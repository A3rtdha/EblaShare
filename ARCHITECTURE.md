## Идея
Один процесс в трее, 5 модулей. Никакого сервера. Пиры общаются напрямую в VPN.

## Модули
1. **core**
   - PeerRegistry (ConcurrentHashMap<UUID, Peer>)
   - DiscoveryService (UDP 6969 broadcast каждые 5с)
   - Config (папка, имя, порты)

2. **filesync**
   - FileWatcher (WatchService: ENTRY_CREATE, MODIFY)
   - HashService (SHA-256)
   - TcpFileServer (port 6970, принимает)
   - TcpFileClient (отправляет чанками 1MB)
   - ConflictResolver (v1: last-write-wins)

3. **monitor**
   - MetricsCollector (OSHI: SystemInfo.getHardware())
   - UdpMetricsBroadcaster
   - UdpMetricsListener

4. **apm**
   - GlobalKeyListener (JNativeHook)
   - CounterStore (Map<Integer, AtomicLong>)
   - DailyReporter (генерит heatmap.html)

5. **ui**
   - TrayManager
   - OverlayWindow (JavaFX, alwaysOnTop, прозрачность 0.85)
   - SettingsDialog

## Потоки
- WatchService thread
- TCP acceptor thread + pool для отправки
- UDP listener thread
- Metrics scheduler (ScheduledExecutor 5s)
- JavaFX UI thread
- JNativeHook native thread

## Протокол
UDP heartbeat:
```json
{"v":1,"id":"a1b2","name":"Koresh","ip":"10.8.0.5","cpu":23.1,"ram":71,"gpu":64,"uptime":41233}
```

TCP file:
```
MAGIC/1
Content-Length: 1234567
SHA-256: abc...
Name: meme.png

<bytes>
```

## Безопасность
- Все только в локальной сети
- Опционально: pre-shared key → AES-GCM для TCP
- APM не пишет текст, только коды клавиш
