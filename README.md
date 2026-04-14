# EblaShare — Магическая Папка для Пацанов

> P2P DropBox + Панель железа пати + APM-трекер. Всё локально, без серверов, работает в Radmin VPN / ZeroTier / обычной локалке.

Закинул файл в `C:\EblaShare` — он через секунду у всех онлайн. Открыл оверлей — видишь, у кого проц кипит, а кто афк. Вечером — тепловая карта клавы.

---

## Стек
- **Java 17**, Gradle (модульный проект)
- `java.nio.file.WatchService`
- TCP sockets + UDP broadcast
- OSHI 6.4.10 — железо
- JNativeHook 2.2.2 — глобальные хуки
- JavaFX 17 + AWT SystemTray
- Jackson

---

## Модули (как у тебя в IDE)

```
ebla-share/
├── core/        DiscoveryService.java
├── filesync/    FileWatcher.java
├── monitor/     MetricsCollector.java
├── apm/         KeyHook.java
└── ui/          TrayApp.java
```

---

## Roadmap v1

### Phase 0 — Bootstrap
### Phase 1 — MagicFolder MVP
### Phase 2 — PartyPanel
### Phase 3 — KeyHeat
