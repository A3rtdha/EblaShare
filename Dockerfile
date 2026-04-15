# =============================================================================
# EblaShare — Dockerfile
# Двухстадийная сборка: Gradle builder → slim runtime
# Назначение: CI/CD + headless-режим (без JavaFX/UI)
# =============================================================================

# ── Stage 1: Builder ─────────────────────────────────────────────────────────
FROM gradle:8.10.2-jdk17 AS builder

WORKDIR /workspace

# Копируем build-скрипты всех модулей (кеш зависимостей)
COPY build.gradle.kts settings.gradle.kts ./
COPY core/build.gradle.kts          core/build.gradle.kts
COPY filesync/build.gradle.kts      filesync/build.gradle.kts
COPY monitor/build.gradle.kts       monitor/build.gradle.kts
COPY apm/build.gradle.kts           apm/build.gradle.kts
COPY ui/build.gradle.kts            ui/build.gradle.kts

# Прогреваем кеш зависимостей без исходников
RUN gradle --no-daemon dependencies --quiet 2>/dev/null || true

# Копируем исходники и собираем (без тестов для скорости)
COPY core/src      core/src
COPY filesync/src  filesync/src
COPY monitor/src   monitor/src
COPY apm/src       apm/src
COPY ui/src        ui/src

# Собираем distribution модуля ui с полным набором runtime-зависимостей
RUN gradle --no-daemon :ui:installDist -x test

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

# Копируем готовый installDist с jar-файлами и всеми зависимостями
COPY --from=builder /workspace/ui/build/install/ui/ /app/

# Порты: UDP discovery + TCP filesync
EXPOSE 6969/udp 6970/tcp

# healthcheck — проверяем, что процесс жив
HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
    CMD pgrep -f "ebla" > /dev/null || exit 1

# Headless-запуск (без JavaFX GUI) — в контейнере нет дисплея
ENV JAVA_TOOL_OPTIONS="-Djava.awt.headless=true"

ENTRYPOINT ["/app/bin/ui"]
