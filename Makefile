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
