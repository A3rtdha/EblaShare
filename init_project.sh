#!/usr/bin/env bash
# =============================================================================
# EblaShare — init_project.sh
# Автоматически создаёт весь DevOps-сетап в текущей директории.
# Запуск: bash init_project.sh
# =============================================================================
set -euo pipefail

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()  { echo -e "${CYAN}[init]${NC} $*"; }
ok()   { echo -e "${GREEN}[ok]${NC}   $*"; }
warn() { echo -e "${YELLOW}[warn]${NC} $*"; }

log "Initializing EblaShare DevOps setup..."
echo ""

# ---------------------------------------------------------------------------
# .gitignore
# ---------------------------------------------------------------------------
log "Writing .gitignore..."
cat > .gitignore << 'GITIGNORE'
# =============================================================================
# EblaShare — .gitignore
# Stack: Java 17 / Gradle (Kotlin DSL) / JavaFX
# IDE:   Cursor (VS Code fork)
# OS:    Windows + Linux + macOS
# =============================================================================

# ── Gradle ───────────────────────────────────────────────────────────────────
.gradle/
build/
**/build/
out/
**/out/
gradle-app.setting
!gradle/wrapper/gradle-wrapper.jar
!gradle/wrapper/gradle-wrapper.properties
.gradletasknamecache

# ── Java ─────────────────────────────────────────────────────────────────────
*.class
*.jar
*.war
*.ear
*.nar
hs_err_pid*
replay_pid*

# ── Cursor / VS Code ─────────────────────────────────────────────────────────
.vscode/*
!.vscode/settings.json
!.vscode/extensions.json
!.vscode/launch.json
!.vscode/tasks.json
.cursor/*
!.cursor/rules/
*.code-workspace
.history/

# ── IntelliJ IDEA (если вдруг) ───────────────────────────────────────────────
.idea/
*.iml
*.iws
*.ipr
out/
.idea_modules/

# ── Docker ───────────────────────────────────────────────────────────────────
.dockerignore

# ── Environment & secrets ────────────────────────────────────────────────────
.env
.env.local
.env.*.local
*.env
!.env.example

# ── OS: macOS ────────────────────────────────────────────────────────────────
.DS_Store
.AppleDouble
.LSOverride
._*
.Spotlight-V100
.Trashes
.fseventsd

# ── OS: Windows ──────────────────────────────────────────────────────────────
Thumbs.db
Thumbs.db:encryptable
ehthumbs.db
Desktop.ini
$RECYCLE.BIN/
*.lnk

# ── OS: Linux ────────────────────────────────────────────────────────────────
*~
.nfs*

# ── Logs & temp ──────────────────────────────────────────────────────────────
*.log
*.tmp
*.temp
logs/
tmp/
temp/

# ── EblaShare runtime artifacts ──────────────────────────────────────────────
heatmap.html
ebla-share-data/
*.sha256
GITIGNORE
ok ".gitignore"

# ---------------------------------------------------------------------------
# .env.example
# ---------------------------------------------------------------------------
log "Writing .env.example..."
cat > .env.example << 'ENVFILE'
# =============================================================================
# EblaShare — .env.example
# Скопируй в .env и заполни перед запуском:  cp .env.example .env
# =============================================================================

# ── Идентификация пира ───────────────────────────────────────────────────────
# Имя, которое будут видеть остальные участники LAN/VPN
EBLA_PEER_NAME=MyPC

# ── Сетевые порты ────────────────────────────────────────────────────────────
# UDP broadcast для обнаружения пиров
EBLA_DISCOVERY_PORT=6969

# TCP сервер для передачи файлов
EBLA_FILE_PORT=6970

# ── Синхронизируемая папка ───────────────────────────────────────────────────
# Путь внутри контейнера (монтируется через docker-compose)
EBLA_SYNC_DIR=/data/ebla-share

# ── Безопасность (опционально) ───────────────────────────────────────────────
# Pre-shared key для AES-GCM шифрования TCP (оставь пустым = без шифрования)
EBLA_PSK=

# ── Мониторинг / метрики ─────────────────────────────────────────────────────
# Интервал сбора метрик в секундах
EBLA_METRICS_INTERVAL_SEC=5

# ── APM / KeyHeat ────────────────────────────────────────────────────────────
# Включить глобальный перехват клавиш (true/false)
# Отключи в контейнере — JNativeHook требует X11/native среду
EBLA_APM_ENABLED=false

# ── JavaFX / UI ──────────────────────────────────────────────────────────────
# Прозрачность overlay-окна (0.0 – 1.0)
EBLA_OVERLAY_OPACITY=0.85

# ── Gradle (только для сборки) ───────────────────────────────────────────────
# Объём памяти для Gradle daemon
GRADLE_OPTS=-Xmx2g -Xms512m

# ── Разное ───────────────────────────────────────────────────────────────────
# Уровень логирования: TRACE / DEBUG / INFO / WARN / ERROR
LOG_LEVEL=INFO
ENVFILE
ok ".env.example"

# ---------------------------------------------------------------------------
# Dockerfile
# ---------------------------------------------------------------------------
log "Writing Dockerfile..."
cat > Dockerfile << 'DOCKERFILE'
# =============================================================================
# EblaShare — Dockerfile
# Двухстадийная сборка: Gradle builder → slim runtime
# Назначение: CI/CD + headless-режим (без JavaFX/UI)
# =============================================================================

# ── Stage 1: Builder ─────────────────────────────────────────────────────────
FROM eclipse-temurin:17-jdk-jammy AS builder

WORKDIR /workspace

# Gradle Wrapper сначала — кешируем зависимости отдельным слоем
COPY gradlew gradlew
COPY gradle/ gradle/
RUN chmod +x gradlew && ./gradlew --version --no-daemon

# Копируем build-скрипты всех модулей (кеш зависимостей)
COPY build.gradle.kts settings.gradle.kts ./
COPY core/build.gradle.kts          core/build.gradle.kts
COPY filesync/build.gradle.kts      filesync/build.gradle.kts
COPY monitor/build.gradle.kts       monitor/build.gradle.kts
COPY apm/build.gradle.kts           apm/build.gradle.kts
COPY ui/build.gradle.kts            ui/build.gradle.kts

# Прогреваем кеш зависимостей без исходников
RUN ./gradlew dependencies --no-daemon --quiet 2>/dev/null || true

# Копируем исходники и собираем (без тестов для скорости)
COPY core/src      core/src
COPY filesync/src  filesync/src
COPY monitor/src   monitor/src
COPY apm/src       apm/src
COPY ui/src        ui/src

# Собираем fat-jar модуля ui (entry-point приложения)
RUN ./gradlew :ui:jar --no-daemon -x test

# ── Stage 2: Runtime ─────────────────────────────────────────────────────────
FROM eclipse-temurin:17-jre-jammy AS runtime

LABEL org.opencontainers.image.title="EblaShare"
LABEL org.opencontainers.image.description="P2P magic folder + party panel"
LABEL org.opencontainers.image.version="0.1.0-SNAPSHOT"

# Минимальные системные зависимости
RUN apt-get update && apt-get install -y --no-install-recommends \
    libxtst6 \
    libxi6 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Папка синхронизации (монтируется снаружи)
RUN mkdir -p /data/ebla-share

# Копируем скомпилированные артефакты
COPY --from=builder /workspace/ui/build/libs/*.jar          /app/ui.jar
COPY --from=builder /workspace/core/build/libs/*.jar        /app/libs/
COPY --from=builder /workspace/filesync/build/libs/*.jar    /app/libs/
COPY --from=builder /workspace/monitor/build/libs/*.jar     /app/libs/
COPY --from=builder /workspace/apm/build/libs/*.jar         /app/libs/

# Порты: UDP discovery + TCP filesync
EXPOSE 6969/udp 6970/tcp

# healthcheck — проверяем, что процесс жив
HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
    CMD pgrep -f "ebla" > /dev/null || exit 1

# Headless-запуск (без JavaFX GUI) — в контейнере нет дисплея
ENV JAVA_TOOL_OPTIONS="-Djava.awt.headless=true"

ENTRYPOINT ["java", \
    "-cp", "/app/ui.jar:/app/libs/*", \
    "-Djava.awt.headless=true", \
    "ebla.ui.TrayApp"]
DOCKERFILE
ok "Dockerfile"

# ---------------------------------------------------------------------------
# .dockerignore
# ---------------------------------------------------------------------------
log "Writing .dockerignore..."
cat > .dockerignore << 'DOCKERIGNORE'
# Исключаем всё лишнее из docker build context
.git/
.gradle/
**/build/
**/out/
.vscode/
.cursor/
*.md
.env
.env.local
logs/
tmp/
*.log
heatmap.html
DOCKERIGNORE
ok ".dockerignore"

# ---------------------------------------------------------------------------
# docker-compose.yaml
# ---------------------------------------------------------------------------
log "Writing docker-compose.yaml..."
cat > docker-compose.yaml << 'COMPOSE'
# =============================================================================
# EblaShare — docker-compose.yaml
# Использование:
#   make up       — поднять всё
#   make down     — остановить
#   make logs     — посмотреть логи
# =============================================================================

services:

  # ── Основной демон EblaShare ───────────────────────────────────────────────
  ebla:
    build:
      context: .
      dockerfile: Dockerfile
      target: runtime           # можно переключить на builder для отладки
    image: ebla-share:local
    container_name: ebla-share

    # Env-файл с реальными значениями (не коммитится)
    env_file:
      - .env

    # Пробрасываем переменные из .env в контейнер
    environment:
      - EBLA_PEER_NAME=${EBLA_PEER_NAME:-DevBox}
      - EBLA_DISCOVERY_PORT=${EBLA_DISCOVERY_PORT:-6969}
      - EBLA_FILE_PORT=${EBLA_FILE_PORT:-6970}
      - EBLA_SYNC_DIR=${EBLA_SYNC_DIR:-/data/ebla-share}
      - EBLA_METRICS_INTERVAL_SEC=${EBLA_METRICS_INTERVAL_SEC:-5}
      - EBLA_APM_ENABLED=false         # в контейнере всегда off
      - LOG_LEVEL=${LOG_LEVEL:-INFO}
      - JAVA_TOOL_OPTIONS=-Djava.awt.headless=true

    ports:
      - "${EBLA_DISCOVERY_PORT:-6969}:6969/udp"   # peer discovery
      - "${EBLA_FILE_PORT:-6970}:6970/tcp"         # file transfer

    volumes:
      # Папка синхронизации — монтируем с хоста
      - ebla-data:/data/ebla-share
      # Логи
      - ./logs:/app/logs

    networks:
      - ebla-net

    restart: unless-stopped

    # Ресурсные лимиты (не падаем на слабой машине)
    deploy:
      resources:
        limits:
          memory: 512M
          cpus: "1.0"
        reservations:
          memory: 128M

  # ── Опциональный: Prometheus для метрик (раскомментируй если нужно) ────────
  # prometheus:
  #   image: prom/prometheus:latest
  #   container_name: ebla-prometheus
  #   volumes:
  #     - ./infra/prometheus.yml:/etc/prometheus/prometheus.yml:ro
  #   ports:
  #     - "9090:9090"
  #   networks:
  #     - ebla-net
  #   depends_on:
  #     - ebla

volumes:
  ebla-data:
    driver: local

networks:
  ebla-net:
    driver: bridge
    # Для работы UDP broadcast нужен host или macvlan.
    # Для локальной разработки bridge достаточен.
    ipam:
      config:
        - subnet: 172.28.0.0/16
COMPOSE
ok "docker-compose.yaml"

# ---------------------------------------------------------------------------
# Makefile
# ---------------------------------------------------------------------------
log "Writing Makefile..."
cat > Makefile << 'MAKEFILE'
# =============================================================================
# EblaShare — Makefile
# Требования: make, docker, docker compose v2
# =============================================================================

.PHONY: help build up down restart logs shell clean fmt check init

# Переменные
COMPOSE      := docker compose
IMAGE        := ebla-share:local
CONTAINER    := ebla-share

## help: показать эту справку
help:
	@echo ""
	@echo "  EblaShare — команды разработки"
	@echo ""
	@grep -E '^## ' Makefile | sed 's/## /  make /'
	@echo ""

## init: первый запуск (cp .env.example → .env, mkdir logs)
init:
	@[ -f .env ] || (cp .env.example .env && echo "Создан .env — заполни его!")
	@mkdir -p logs
	@echo "✓ Готово. Запусти: make up"

## build: собрать Docker-образ
build:
	$(COMPOSE) build --no-cache

## up: поднять контейнеры (сборка если нужно)
up:
	$(COMPOSE) up -d --build

## down: остановить и удалить контейнеры
down:
	$(COMPOSE) down

## restart: перезапустить сервис
restart:
	$(COMPOSE) restart ebla

## logs: хвост логов (Ctrl+C для выхода)
logs:
	$(COMPOSE) logs -f --tail=100

## shell: войти в контейнер
shell:
	docker exec -it $(CONTAINER) /bin/bash

## clean: удалить контейнеры, тома, образы
clean:
	$(COMPOSE) down -v --rmi local
	docker system prune -f

## gradle-build: собрать jar локально через Gradle Wrapper
gradle-build:
	./gradlew :ui:jar --no-daemon

## gradle-clean: очистить build-артефакты
gradle-clean:
	./gradlew clean --no-daemon

## check: проверить, что docker и compose доступны
check:
	@command -v docker    >/dev/null 2>&1 || (echo "✗ Docker не найден"          && exit 1)
	@docker compose version >/dev/null 2>&1 || (echo "✗ docker compose не найден" && exit 1)
	@[ -f .env ] || (echo "✗ Нет .env — запусти: make init"                      && exit 1)
	@echo "✓ Всё на месте"

## status: статус контейнеров
status:
	$(COMPOSE) ps
MAKEFILE
ok "Makefile"

# ---------------------------------------------------------------------------
# .vscode/settings.json
# ---------------------------------------------------------------------------
log "Writing .vscode/settings.json..."
mkdir -p .vscode
cat > .vscode/settings.json << 'SETTINGS'
{
  // ── Java / Gradle ─────────────────────────────────────────────────────────
  "java.configuration.updateBuildConfiguration": "automatic",
  "java.compile.nullAnalysis.mode": "automatic",
  "java.inlayHints.parameterNames.enabled": "all",
  "java.jdt.ls.java.home": "",
  "gradle.nestedProjects": true,
  "gradle.autoDetect": "on",
  "java.import.gradle.enabled": true,
  "java.import.gradle.wrapper.enabled": true,
  "java.format.settings.url": ".vscode/java-formatter.xml",
  "java.format.onType.enabled": true,
  "java.saveActions.organizeImports": true,

  // ── Editor ────────────────────────────────────────────────────────────────
  "editor.tabSize": 4,
  "editor.insertSpaces": true,
  "editor.formatOnSave": true,
  "editor.formatOnPaste": true,
  "editor.rulers": [120],
  "editor.wordWrap": "off",
  "editor.bracketPairColorization.enabled": true,
  "editor.guides.bracketPairs": "active",
  "editor.suggestSelection": "first",
  "editor.quickSuggestions": {
    "other": "on",
    "comments": "off",
    "strings": "on"
  },

  // ── Files ─────────────────────────────────────────────────────────────────
  "files.trimTrailingWhitespace": true,
  "files.insertFinalNewline": true,
  "files.encoding": "utf8",
  "files.eol": "\n",
  "files.exclude": {
    "**/.git": true,
    "**/.gradle": true,
    "**/build": true,
    "**/out": true,
    "**/.idea": true
  },
  "files.watcherExclude": {
    "**/.gradle/**": true,
    "**/build/**": true,
    "**/out/**": true
  },

  // ── Search ────────────────────────────────────────────────────────────────
  "search.exclude": {
    "**/.gradle": true,
    "**/build": true,
    "**/out": true
  },

  // ── Git ───────────────────────────────────────────────────────────────────
  "git.autofetch": true,
  "git.confirmSync": false,
  "git.enableSmartCommit": true,

  // ── Docker ────────────────────────────────────────────────────────────────
  "docker.showStartPage": false,

  // ── Terminal ──────────────────────────────────────────────────────────────
  "terminal.integrated.defaultProfile.linux": "bash",
  "terminal.integrated.defaultProfile.windows": "Git Bash",
  "terminal.integrated.scrollback": 10000,

  // ── Misc ──────────────────────────────────────────────────────────────────
  "workbench.editor.enablePreview": false,
  "explorer.confirmDelete": false,
  "explorer.compactFolders": false,
  "breadcrumbs.enabled": true
}
SETTINGS
ok ".vscode/settings.json"

# ---------------------------------------------------------------------------
# .vscode/extensions.json
# ---------------------------------------------------------------------------
log "Writing .vscode/extensions.json..."
cat > .vscode/extensions.json << 'EXTENSIONS'
{
  "recommendations": [
    // ── Java core ────────────────────────────────────────────────────────────
    "redhat.java",
    "vscjava.vscode-java-pack",
    "vscjava.vscode-gradle",
    "vscjava.vscode-java-debug",
    "vscjava.vscode-java-test",
    "vscjava.vscode-maven",

    // ── Docker ───────────────────────────────────────────────────────────────
    "ms-azuretools.vscode-docker",
    "ms-vscode-remote.remote-containers",

    // ── Git ──────────────────────────────────────────────────────────────────
    "eamodio.gitlens",
    "mhutchie.git-graph",
    "github.vscode-pull-request-github",

    // ── Quality of life ──────────────────────────────────────────────────────
    "editorconfig.editorconfig",
    "streetsidesoftware.code-spell-checker",
    "streetsidesoftware.code-spell-checker-russian",
    "usernamehw.errorlens",
    "gruntfuggly.todo-tree",
    "mikestead.dotenv",
    "tamasfe.even-better-toml",
    "redhat.vscode-yaml",
    "ms-vscode.makefile-tools",

    // ── Theme / icons ────────────────────────────────────────────────────────
    "pkief.material-icon-theme",
    "zhuangtongfa.material-theme"
  ]
}
EXTENSIONS
ok ".vscode/extensions.json"

# ---------------------------------------------------------------------------
# .vscode/launch.json
# ---------------------------------------------------------------------------
log "Writing .vscode/launch.json..."
cat > .vscode/launch.json << 'LAUNCH'
{
  "version": "0.2.0",
  "configurations": [
    {
      "type": "java",
      "name": "EblaShare (TrayApp)",
      "request": "launch",
      "mainClass": "ebla.ui.TrayApp",
      "projectName": "ui",
      "vmArgs": "-Djava.awt.headless=false -Xmx512m",
      "env": {
        "EBLA_PEER_NAME": "DevLocal",
        "EBLA_DISCOVERY_PORT": "6969",
        "EBLA_FILE_PORT": "6970",
        "EBLA_SYNC_DIR": "${workspaceFolder}/tmp/sync",
        "EBLA_APM_ENABLED": "true",
        "LOG_LEVEL": "DEBUG"
      }
    },
    {
      "type": "java",
      "name": "EblaShare (Headless / Docker-like)",
      "request": "launch",
      "mainClass": "ebla.ui.TrayApp",
      "projectName": "ui",
      "vmArgs": "-Djava.awt.headless=true -Xmx256m",
      "env": {
        "EBLA_PEER_NAME": "HeadlessNode",
        "EBLA_DISCOVERY_PORT": "6969",
        "EBLA_FILE_PORT": "6970",
        "EBLA_SYNC_DIR": "${workspaceFolder}/tmp/sync",
        "EBLA_APM_ENABLED": "false",
        "LOG_LEVEL": "DEBUG"
      }
    }
  ]
}
LAUNCH
ok ".vscode/launch.json"

# ---------------------------------------------------------------------------
# .vscode/tasks.json
# ---------------------------------------------------------------------------
log "Writing .vscode/tasks.json..."
cat > .vscode/tasks.json << 'TASKS'
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Gradle: Build",
      "type": "shell",
      "command": "./gradlew :ui:jar --no-daemon",
      "group": { "kind": "build", "isDefault": true },
      "presentation": { "reveal": "always", "panel": "shared" },
      "problemMatcher": "$gradle"
    },
    {
      "label": "Gradle: Clean",
      "type": "shell",
      "command": "./gradlew clean --no-daemon",
      "group": "build",
      "presentation": { "reveal": "always" },
      "problemMatcher": []
    },
    {
      "label": "Docker: Up",
      "type": "shell",
      "command": "make up",
      "group": "none",
      "presentation": { "reveal": "always", "panel": "new" },
      "problemMatcher": []
    },
    {
      "label": "Docker: Down",
      "type": "shell",
      "command": "make down",
      "group": "none",
      "presentation": { "reveal": "silent" },
      "problemMatcher": []
    },
    {
      "label": "Docker: Logs",
      "type": "shell",
      "command": "make logs",
      "group": "none",
      "isBackground": true,
      "presentation": { "reveal": "always", "panel": "new" },
      "problemMatcher": []
    }
  ]
}
TASKS
ok ".vscode/tasks.json"

# ---------------------------------------------------------------------------
# .editorconfig
# ---------------------------------------------------------------------------
log "Writing .editorconfig..."
cat > .editorconfig << 'EDITORCONFIG'
root = true

[*]
charset = utf-8
end_of_line = lf
indent_style = space
indent_size = 4
trim_trailing_whitespace = true
insert_final_newline = true

[*.{yml,yaml,json,kts,toml}]
indent_size = 2

[Makefile]
indent_style = tab

[*.md]
trim_trailing_whitespace = false
EDITORCONFIG
ok ".editorconfig"

# ---------------------------------------------------------------------------
# infra/ — заготовки для будущего мониторинга
# ---------------------------------------------------------------------------
log "Writing infra/prometheus.yml (заготовка)..."
mkdir -p infra
cat > infra/prometheus.yml << 'PROM'
# Базовая конфигурация Prometheus (раскомментируй сервис в docker-compose)
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: "ebla-share"
    static_configs:
      - targets: ["ebla:9090"]  # JVM metrics endpoint (если добавишь Micrometer)
PROM
ok "infra/prometheus.yml"

# ---------------------------------------------------------------------------
# logs/ directory
# ---------------------------------------------------------------------------
mkdir -p logs
touch logs/.gitkeep
ok "logs/.gitkeep"

# ---------------------------------------------------------------------------
# tmp/sync directory (для локального запуска без Docker)
# ---------------------------------------------------------------------------
mkdir -p tmp/sync
touch tmp/.gitkeep
ok "tmp/.gitkeep"

# ---------------------------------------------------------------------------
# Финальный баннер
# ---------------------------------------------------------------------------
echo ""
echo -e "${GREEN}============================================================${NC}"
echo -e "${GREEN}  EblaShare DevOps setup готов!${NC}"
echo -e "${GREEN}============================================================${NC}"
echo ""
echo "  Следующие шаги:"
echo ""
echo "  1. cp .env.example .env  (и заполни EBLA_PEER_NAME)"
echo "  2. make check            (проверить зависимости)"
echo "  3. make up               (поднять контейнеры)"
echo "  4. make logs             (смотреть логи)"
echo ""
echo "  Локально (без Docker):"
echo "  ./gradlew :ui:jar --no-daemon"
echo "  Затем нажми F5 в Cursor → 'EblaShare (TrayApp)'"
echo ""
echo -e "${CYAN}  Cursor Extensions:${NC} Ctrl+Shift+P → 'Show Recommended Extensions'"
echo ""
