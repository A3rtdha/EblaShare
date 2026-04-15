package ebla.core;

import java.util.Collection;
import java.util.Collections;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;
import java.util.logging.Logger;

/**
 * Потокобезопасное хранилище пиров с автоматическим удалением "мертвых" узлов по истечении TTL.
 */
public class PeerRegistry {

    // TODO(CORE-3): заменить на org.slf4j.Logger после подключения slf4j + logback
    private static final Logger log = Logger.getLogger(PeerRegistry.class.getName());

    private final ConcurrentHashMap<UUID, Peer> peers = new ConcurrentHashMap<>();
    private final ScheduledExecutorService cleanupScheduler;

    private final long ttlMillis;
    private final long cleanupIntervalMillis;

    /**
     * Создает реестр с настраиваемым TTL и интервалом очистки.
     *
     * @param ttlMillis            время жизни пира в мс с момента последнего обновления (lastSeen)
     * @param cleanupIntervalMillis интервал запуска задачи очистки в мс
     */
    public PeerRegistry(long ttlMillis, long cleanupIntervalMillis) {
        this.ttlMillis = ttlMillis;
        this.cleanupIntervalMillis = cleanupIntervalMillis;
        // Daemon-поток, чтобы не блокировать завершение приложения
        this.cleanupScheduler = Executors.newSingleThreadScheduledExecutor(r -> {
            Thread t = new Thread(r, "PeerRegistry-Cleanup");
            t.setDaemon(true);
            return t;
        });
    }

    /**
     * Реестр по умолчанию: TTL = 30 секунд, очистка каждые 10 секунд.
     */
    public PeerRegistry() {
        this(30_000L, 10_000L);
    }

    /**
     * Запускает фоновый процесс очистки.
     */
    public void start() {
        cleanupScheduler.scheduleAtFixedRate(this::cleanupDeadPeers,
                cleanupIntervalMillis, cleanupIntervalMillis, TimeUnit.MILLISECONDS);
        log.info("PeerRegistry started. TTL=" + ttlMillis + "ms, cleanup interval=" + cleanupIntervalMillis + "ms");
    }
    /**
     * Останавливает фоновый процесс очистки.
     */
    public void stop() {
        cleanupScheduler.shutdown();
        try {
            if (!cleanupScheduler.awaitTermination(5, TimeUnit.SECONDS)) {
                cleanupScheduler.shutdownNow();
            }
        } catch (InterruptedException e) {
            cleanupScheduler.shutdownNow();
            Thread.currentThread().interrupt();
        }
        log.info("PeerRegistry stopped.");
    }

    /**
     * Добавляет нового пира или обновляет существующего.
     * Если у пира lastSeen == 0, автоматически устанавливается текущее время.
     */
    public void addOrUpdate(Peer peer) {
        if (peer == null || peer.getId() == null) {
            throw new IllegalArgumentException("Peer and Peer ID must not be null");
        }

        if (peer.getLastSeen() == 0) {
            peer.setLastSeen(System.currentTimeMillis());
        }

        peers.put(peer.getId(), peer);
    }

    /**
     * Обновляет время lastSeen для пира, если он присутствует в реестре.
     * Используется для heartbeat-сигналов.
     *
     * @return true, если пир был найден и обновлен, иначе false
     */
    public boolean touch(UUID id) {
        Peer peer = peers.get(id);
        if (peer != null) {
            peer.setLastSeen(System.currentTimeMillis());
            return true;
        }
        return false;
    }

    public Peer get(UUID id) {
        return peers.get(id);
    }

    public void remove(UUID id) {
        peers.remove(id);
    }

    /**
     * Возвращает немодифицируемое представление всех активных пиров.
     */
    public Collection<Peer> getAll() {
        return Collections.unmodifiableCollection(peers.values());
    }

    public int size() {
        return peers.size();
    }

    /**
     * Очищает реестр от пиров, у которых время с момента lastSeen превышает TTL.
     */
    private void cleanupDeadPeers() {
        long now = System.currentTimeMillis();
        peers.entrySet().removeIf(entry -> {
            long lastSeen = entry.getValue().getLastSeen();
            // Защита от пиров с некорректным lastSeen из будущего
            if (lastSeen > now) {
                return false;
            }
            boolean isDead = (now - lastSeen) > ttlMillis;
            if (isDead) {
                log.info("Removing dead peer: " + entry.getValue());
            }
            return isDead;
        });
    }
}
