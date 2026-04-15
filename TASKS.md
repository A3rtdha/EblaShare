# EblaShare Backlog

## Статусы

- `DONE` — закрыто и уже есть в репо
- `WIP` — начато, но acceptance еще не выполнен
- `NEXT` — ближайший разумный шаг
- `TODO` — нужно, но не прямо сейчас
- `PARKED` — сознательно откладываем до MVP+

## Легенда Story Points

- `1 SP` — мелкий класс или простая модель
- `2 SP` — полдня, понятная логика без сильного риска
- `3 SP` — день работы, есть API/edge cases
- `5 SP` — заметная фича с сетью, потоками или tricky OS behavior
- `8 SP` — слишком жирно, надо дробить

## Роли

- `Aertdha` — архитектура, сеть, интеграции, ревью сложных мест
- `Zaki` — модели, конфиг, тесты, локальные сервисы, документация и безопасные UI/data задачи

---

## Снимок состояния

Уже сделано:

- `CORE-1` — есть `Peer.java`
- `INFRA-1` — есть multi-module Gradle, wrapper и fat jar
- `INFRA-2` — есть Docker bootstrap, `run.sh`, `docker-compose.yaml`, README smoke test

Начато, но не завершено:

- `UI-0` — headless bootstrap для контейнера
- `DiscoveryService`, `FileWatcher`, `MetricsCollector`, `KeyHook` пока только заглушки

Главный вывод:

- инфраструктура запуска уже собрана;
- следующий полезный слой работы — `config -> registry -> discovery -> filesync`;
- APM и красивый UI пока не блокируют MVP и не должны тормозить core flow.

---

## Порядок работ

1. Добить базовый runtime: конфиг, логирование, wiring.
2. Сделать peer discovery и живой registry.
3. Сделать file watcher + hash + TCP transfer.
4. Только потом подтягивать UI binding и APM.

---

## Epic 1: Core & Discovery

| ID | Pri | SP | Status | Owner | Задача | Что делаем | Done when |
| --- | --- | ---: | --- | --- | --- | --- | --- |
| `CORE-1` | P0 | 1 | `DONE` | `Zaki` | Модель `Peer` | Оставить текущий `record` как базовую модель пира. | `Peer.java` хранит `id`, `name`, `ip`, `lastSeen`, `metrics`; `equals/hashCode` по `id`. |
| `CORE-2` | P0 | 2 | `NEXT` | `Zaki` | `AppConfig` loader | Грузить `~/.eblashare/config.yml`, создать файл по умолчанию, уметь переопределять env-переменными Docker/runtime. | Есть `AppConfig`, загрузка не падает на отсутствии файла, дефолты создаются автоматически. |
| `CORE-3` | P0 | 2 | `NEXT` | `Zaki` | Логирование | Подключить `slf4j` + `logback`, убрать `System.out` из bootstrap-логики по мере роста приложения. | Консольные и файловые логи работают, уровень задается из конфига/env. |
| `CORE-4` | P0 | 3 | `NEXT` | `Aertdha` | `PeerRegistry` | Потокобезопасное хранилище пиров с TTL cleanup. | Можно add/update/get peers, "мертвые" пиры удаляются по таймеру. |
| `CORE-5` | P1 | 2 | `TODO` | `Zaki` | Discovery payload model | Зафиксировать модель UDP heartbeat: версия протокола, peer id, имя, ip, метрики. | Есть сериализуемая модель пакета и тест на round-trip JSON. |
| `CORE-6` | P1 | 5 | `TODO` | `Aertdha` | UDP discovery service | Два потока: broadcast heartbeat и listener, связка с `PeerRegistry`. | Две локальные ноды видят друг друга и обновляют `lastSeen`. |

---

## Epic 2: FileSync

| ID | Pri | SP | Status | Owner | Задача | Что делаем | Done when |
| --- | --- | ---: | --- | --- | --- | --- | --- |
| `SYNC-1` | P1 | 3 | `TODO` | `Zaki` | `FileWatcher` | WatchService + debounce + ignore временных файлов. | Коллбэк стреляет только на готовые файлы, без дублей на типовом сценарии Windows. |
| `SYNC-2` | P1 | 2 | `TODO` | `Zaki` | `HashService` | SHA-256 батчами, без чтения целого файла в память. | Хеш работает на маленьких и больших файлах, есть unit test. |
| `SYNC-3` | P1 | 2 | `TODO` | `Aertdha` | Контракт TCP transfer | Описать header/body формат и record-модели. | Формат зафиксирован в коде и/или доке, клиент и сервер используют одну модель. |
| `SYNC-4` | P1 | 5 | `TODO` | `Aertdha` | `TcpFileServer` | Прием файла чанками, запись в sync dir, без OOM. | Файл корректно принимается и сохраняется. |
| `SYNC-5` | P1 | 5 | `TODO` | `Aertdha` | `TcpFileClient` | Рассылка нового файла известным пирам через пул потоков. | Один файл успешно улетает минимум двум пирам. |
| `SYNC-6` | P1 | 3 | `TODO` | `Aertdha` | Echo protection | Кэш недавно полученных хешей, чтобы не зациклить пересылку. | Нет бесконечной переотправки одного и того же файла. |

---

## Epic 3: Monitor

| ID | Pri | SP | Status | Owner | Задача | Что делаем | Done when |
| --- | --- | ---: | --- | --- | --- | --- | --- |
| `MON-1` | P1 | 1 | `TODO` | `Zaki` | Модель `Metrics` | Нормальная typed-модель вместо `Map<String, Object>` везде, где это возможно. | Есть класс/record метрик с CPU/RAM и сериализацией. |
| `MON-2` | P1 | 3 | `TODO` | `Aertdha` | `MetricsCollector` | Сбор CPU/RAM через OSHI раз в несколько секунд. | В логах локальной ноды видны реальные CPU/RAM значения. |
| `MON-3` | P1 | 2 | `TODO` | `Aertdha` | Интеграция с discovery | Встраивать метрики в heartbeat payload. | Другая нода видит метрики соседа в registry. |
| `MON-4` | P3 | 2 | `PARKED` | `Aertdha` | GPU/температуры | Добавлять только если OSHI даёт стабильные данные на целевых машинах. | Либо поддержано и протестировано, либо сознательно выкинуто из MVP. |

---

## Epic 4: UI

| ID | Pri | SP | Status | Owner | Задача | Что делаем | Done when |
| --- | --- | ---: | --- | --- | --- | --- | --- |
| `UI-0` | P0 | 2 | `WIP` | `Aertdha` | Headless bootstrap | Текущий `TrayApp` держит контейнер живым и создает sync dir. | Bootstrap перенесен на более чистую архитектуру, но docker/headless path не ломается. |
| `UI-1` | P2 | 3 | `TODO` | `Zaki` | Tray manager | Иконка, выход, открыть папку, открыть настройки. | Приложение живет в трее и корректно завершается. |
| `UI-2` | P2 | 3 | `TODO` | `Zaki` | Overlay skeleton | Простейшее окно с dummy data или registry snapshot. | Окно открывается, закрывается, не ломает headless mode. |
| `UI-3` | P2 | 3 | `TODO` | `Aertdha` | UI binding | Безопасно обновлять UI из фоновых потоков. | Таблица пиров показывает актуальные значения без блокировки UI thread. |

---

## Epic 5: APM

| ID | Pri | SP | Status | Owner | Задача | Что делаем | Done when |
| --- | --- | ---: | --- | --- | --- | --- | --- |
| `APM-1` | P3 | 5 | `PARKED` | `Aertdha` | Global hook | Возвращать `JNativeHook` только после стабилизации core sync/discovery. | Есть рабочий расчет APM и понятная деградация на headless/system без hook. |
| `APM-2` | P3 | 3 | `PARKED` | `Zaki` | Хранилище статистики | Сохранять статы на диск и поднимать после рестарта. | Данные переживают рестарт. |
| `APM-3` | P3 | 3 | `PARKED` | `Zaki` | HTML report | Генерировать `report.html`/heatmap из накопленной статистики. | Отчет открывается локально в браузере. |

---

## Epic 6: Infrastructure

| ID | Pri | SP | Status | Owner | Задача | Что делаем | Done when |
| --- | --- | ---: | --- | --- | --- | --- | --- |
| `INFRA-1` | P0 | 2 | `DONE` | `Aertdha` | Gradle setup | Wrapper, multi-module build, fat jar, `gradlew build`. | `./gradlew build` и `.\gradlew.bat build` зеленые. |
| `INFRA-2` | P0 | 2 | `DONE` | `Aertdha` | Docker/bootstrap | `Dockerfile`, `docker-compose.yaml`, `run.sh`, healthcheck, smoke test. | `bash run.sh up` поднимает healthy контейнер. |
| `INFRA-3` | P0 | 1 | `WIP` | `Zaki` | Repo hygiene/docs | `.gitignore`, `.env.example`, README, базовые VS Code файлы. | Репо чистое, build artifacts не коммитятся, README не врет. |
| `INFRA-4` | P1 | 2 | `TODO` | `Zaki` | Unit test baseline | Подключить JUnit 5 для полезных low-level сервисов. | Есть хотя бы тесты на `HashService`, config loader и discovery payload JSON. |
| `INFRA-5` | P2 | 2 | `TODO` | `Aertdha` | CI smoke build | GitHub Actions или аналог: `gradlew build` на пуш/PR. | PR падает, если проект перестал собираться. |

---

## Что не нужно делать прямо сейчас

- Не тащить Prometheus/Grafana в MVP, пока нет базового discovery/filesync.
- Не тратить время на AES-GCM, пока не работает простой TCP flow.
- Не делать сложный UI раньше, чем появятся реальные данные из registry.
- Не возвращать `JNativeHook` в docker/headless path без отдельного desktop сценария запуска.

---

## Ближайшие 5 задач

1. `CORE-2` — `AppConfig` loader
2. `CORE-3` — логирование
3. `CORE-4` — `PeerRegistry`
4. `CORE-5` — discovery payload model
5. `CORE-6` — UDP discovery service
