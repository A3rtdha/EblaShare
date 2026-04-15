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

## Модули

```text
ebla-share/
├── core/        DiscoveryService.java
├── filesync/    FileWatcher.java
├── monitor/     MetricsCollector.java
├── apm/         KeyHook.java
└── ui/          TrayApp.java
```

---

## Текущее состояние

Сейчас проект умеет:

- собираться через `Gradle Wrapper`;
- подниматься через `Docker Compose`;
- запускать headless bootstrap внутри контейнера;
- писать heartbeat в логи контейнера.

Сейчас проект еще не умеет:

- обнаруживать пиров;
- синкать файлы;
- собирать реальные метрики;
- показывать UI/tray;
- считать APM.

То есть инфраструктура запуска уже живая, а основная функциональность пока в статусе `stub / WIP`.

---

## Быстрый старт

### 1. Через Docker

Windows + WSL2 сейчас самый удобный путь:

```bash
cd /mnt/d/CODING/dayn/EblaShare
cp .env.example .env
bash run.sh up
```

Полезные команды:

```bash
bash run.sh logs
bash run.sh status
bash run.sh down
```

Ожидаемый результат:

- контейнер `ebla-share` в статусе `Up`;
- в логах есть `boot`;
- в логах идут `heartbeat`.

### 2. Локальная сборка через Gradle Wrapper

В PowerShell:

```powershell
Set-Location D:\CODING\dayn\EblaShare
.\gradlew.bat build --no-daemon --console=plain
```

Собранные артефакты:

```text
ui/build/libs/ui-0.1.0-SNAPSHOT-all.jar
ui/build/libs/ui-0.1.0-SNAPSHOT.jar
```

### 3. Локальный запуск fat jar

В PowerShell:

```powershell
java -jar .\ui\build\libs\ui-0.1.0-SNAPSHOT-all.jar
```

Это запускает текущий bootstrap без Docker.

---

## Smoke Test

### Docker smoke test

```bash
bash run.sh up
bash run.sh status
bash run.sh logs
```

### Проверка volume

```bash
docker compose exec ebla sh -lc 'echo test > /data/ebla-share/hello.txt && ls -la /data/ebla-share'
bash run.sh restart
docker compose exec ebla ls -la /data/ebla-share
```

Если `hello.txt` пережил рестарт, volume работает.

---

## Полезные файлы

- `TASKS.md` — декомпозиция задач и acceptance criteria
- `ARCHITECTURE.md` — схема модулей и протоколов
- `run.sh` — команды запуска для Bash/WSL
- `Makefile` — альтернативные dev-команды
- `docker-compose.yaml` — контейнерный запуск

---

## Roadmap v1

### Phase 0 — Bootstrap

### Phase 1 — MagicFolder MVP

### Phase 2 — PartyPanel

### Phase 3 — KeyHeat
