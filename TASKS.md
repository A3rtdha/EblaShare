# EblaShare — Task Board

## Роли
- **A (Middle/Middle+)**: сеть, многопоточность, протокол, OSHI, архитектура
- **Z (Trainee)**: модели, UI скелет, логирование, простые утилиты, тесты

## Epic 1: Core & Discovery
| ID | Задача | Кому | Приоритет | Acceptance |
|---|---|---|---|---|
| CORE-1 | Peer модель (id UUID, name, ip, lastSeen) | Z | P0 | record Peer, equals по id |
| CORE-2 | Config loader (yaml/properties: папка, имя, порты) | Z | P0 | читает ~/.eblashare/config |
| CORE-3 | DiscoveryService UDP broadcast 6969 | A | P0 | шлет каждые 5с, слушает ответы |
| CORE-4 | PeerRegistry (ConcurrentHashMap + TTL 15с) | A | P0 | автоудаление мертвых пиров |
| CORE-5 | Логирование (SLF4J + logback) | Z | P1 | логи в файл |

## Epic 2: FileSync — Магическая папка
| ID | Задача | Кому | Приоритет | Acceptance |
|---|---|---|---|---|
| SYNC-1 | FileWatcher на WatchService (CREATE, MODIFY) | Z | P0 | логирует события, игнор .tmp |
| SYNC-2 | HashService SHA-256 | Z | P0 | метод hash(Path) |
| SYNC-3 | TCP протокол: header + body | A | P0 | MAGIC/1, JSON header, чанки 1MB |
| SYNC-4 | TcpFileServer (port 6970) | A | P0 | принимает, проверяет хеш, пишет |
| SYNC-5 | TcpFileClient + очередь отправки | A | P0 | отправляет всем пирам параллельно |
| SYNC-6 | Дедупликация и игнор своих событий | A | P1 | не шлем файл который только что приняли |
| SYNC-7 | Обработка DELETE | Z | P2 | удаляет у пиров (опционально) |

## Epic 3: Monitor — Панель железа
| ID | Задача | Кому | Приоритет | Acceptance |
|---|---|---|---|---|
| MON-1 | MetricsCollector через OSHI | A | P0 | cpuLoad, ramUsed, gpuTemp, uptime |
| MON-2 | UdpMetricsBroadcaster (встроить в Discovery) | A | P0 | шлет метрики в том же пакете |
| MON-3 | UdpMetricsListener + обновление Peer | A | P1 | парсит JSON |
| MON-4 | Модель Metrics | Z | P0 | простой POJO |

## Epic 4: UI
| ID | Задача | Кому | Приоритет | Acceptance |
|---|---|---|---|---|
| UI-1 | TrayApp + иконка в трее | Z | P0 | меню: Open folder, Exit |
| UI-2 | JavaFX Overlay скелет | Z | P1 | полупрозрачное окно поверх |
| UI-3 | Отображение списка пиров | A | P1 | таблица с CPU/RAM, автообновление |
| UI-4 | Настройки (имя, папка) | Z | P2 | простой диалог |

## Epic 5: APM — KeyHeat
| ID | Задача | Кому | Приоритет | Acceptance |
|---|---|---|---|---|
| APM-1 | KeyHook через JNativeHook (слушатель) | A | P0 | считает нажатия, НЕ логирует текст |
| APM-2 | CounterStore (Map<Integer, AtomicLong>) | Z | P0 | сохранение раз в минуту |
| APM-3 | DailyReporter HTML тепловая карта | Z | P1 | генерит heatmap.html |
| APM-4 | График APM по часам | Z | P2 | Chart.js в HTML |

## Epic 6: Инфраструктура
| ID | Задача | Кому | Приоритет | Acceptance |
|---|---|---|---|---|
| INFRA-1 | Gradle многомодульный билд Java 17 | A | P0 | ./gradlew run работает |
| INFRA-2 | .gitignore, README, ARCHITECTURE | Z | P0 | готово |
| INFRA-3 | Unit тесты для HashService, PeerRegistry | Z | P1 | JUnit 5 |
| INFRA-4 | GitHub Actions CI (build) | A | P2 | |

## Как делить работу — первые 2 недели

**Неделя 1:**
- A: CORE-3, CORE-4, INFRA-1, SYNC-3 (протокол)
- Z: CORE-1, CORE-2, CORE-5, UI-1, INFRA-2

Результат: приложение запускается, пиры видят друг друга в логах.

**Неделя 2:**
- A: SYNC-4, SYNC-5, MON-1, MON-2
- Z: SYNC-1, SYNC-2, MON-4, APM-2

Результат: кинул файл в EblaShare — он прилетел второму компу.

**Правило для Trainee:** бери задачи где нет сокетов и многопоточности. Все что связано с ConcurrentHashMap, ExecutorService, NIO — отдавай Middle.

**Правило для Middle:** делай ревью каждого PR Trainee в тот же день. Оставляй скелеты интерфейсов, чтобы Trainee мог имплементить.

Хочешь — сделаю готовые GitHub Issues с лейблами.
