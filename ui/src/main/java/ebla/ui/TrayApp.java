package ebla.ui;

import java.nio.file.Files;
import java.nio.file.Path;
import java.time.Instant;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;

/** Минимальный bootstrap для headless-контейнера. */
public final class TrayApp {
    private TrayApp() {
    }

    public static void main(String[] args) throws Exception {
        String peerName = env("EBLA_PEER_NAME", "DevBox");
        String syncDir = env("EBLA_SYNC_DIR", "/data/ebla-share");
        int intervalSec = envInt("EBLA_METRICS_INTERVAL_SEC", 5);
        String logLevel = env("LOG_LEVEL", "INFO");

        Files.createDirectories(Path.of(syncDir));

        System.out.printf(
                "[ebla] boot peer=%s syncDir=%s logLevel=%s startedAt=%s%n",
                peerName,
                syncDir,
                logLevel,
                Instant.now()
        );

        ScheduledExecutorService heartbeat = Executors.newSingleThreadScheduledExecutor(r -> {
            Thread thread = new Thread(r, "ebla-heartbeat");
            thread.setDaemon(true);
            return thread;
        });

        heartbeat.scheduleAtFixedRate(
                () -> System.out.printf(
                        "[ebla] heartbeat peer=%s syncDir=%s ts=%s%n",
                        peerName,
                        syncDir,
                        Instant.now()
                ),
                0,
                Math.max(intervalSec, 5),
                TimeUnit.SECONDS
        );

        CountDownLatch shutdownLatch = new CountDownLatch(1);
        Runtime.getRuntime().addShutdownHook(new Thread(() -> {
            System.out.println("[ebla] shutdown requested");
            heartbeat.shutdownNow();
            shutdownLatch.countDown();
        }, "ebla-shutdown"));

        shutdownLatch.await();
    }

    private static String env(String name, String defaultValue) {
        String value = System.getenv(name);
        return value == null || value.isBlank() ? defaultValue : value;
    }

    private static int envInt(String name, int defaultValue) {
        try {
            return Integer.parseInt(env(name, String.valueOf(defaultValue)));
        } catch (NumberFormatException ignored) {
            return defaultValue;
        }
    }
}
