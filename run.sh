#!/usr/bin/env bash
# =============================================================================
# EblaShare — run.sh  (замена make для Windows Git Bash)
# Использование: bash run.sh [команда]
# =============================================================================
set -euo pipefail

GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
log()  { echo -e "${CYAN}[ebla]${NC} $*"; }
ok()   { echo -e "${GREEN}[ok]${NC}   $*"; }
err()  { echo -e "${RED}[err]${NC}  $*"; exit 1; }
warn() { echo -e "${YELLOW}[warn]${NC} $*"; }

CMD="${1:-help}"

case "$CMD" in

  help)
    echo ""
    echo "  EblaShare — команды:"
    echo ""
    echo "  bash run.sh init          — первый запуск (.env + папки)"
    echo "  bash run.sh check         — проверить docker и .env"
    echo "  bash run.sh build         — собрать Docker-образ"
    echo "  bash run.sh up            — поднять контейнеры"
    echo "  bash run.sh down          — остановить контейнеры"
    echo "  bash run.sh restart       — перезапустить"
    echo "  bash run.sh logs          — показать логи (Ctrl+C выход)"
    echo "  bash run.sh shell         — войти в контейнер"
    echo "  bash run.sh clean         — удалить всё (контейнеры, тома, образ)"
    echo "  bash run.sh gradle-build  — собрать jar локально"
    echo "  bash run.sh status        — статус контейнеров"
    echo ""
    ;;

  init)
    [ -f .env ] && warn ".env уже существует, не перезаписываю" || (cp .env.example .env && ok "Создан .env — открой и заполни EBLA_PEER_NAME")
    mkdir -p logs tmp/sync
    ok "Готово. Следующий шаг: bash run.sh up"
    ;;

  check)
    log "Проверяю окружение..."
    command -v docker >/dev/null 2>&1    || err "Docker не найден — установи с https://docs.docker.com/desktop/windows/"
    docker compose version >/dev/null 2>&1 || err "docker compose не найден (нужен Docker Desktop >= 3.x)"
    docker info >/dev/null 2>&1          || err "Docker daemon не запущен — запусти Docker Desktop"
    [ -f .env ]                          || err "Нет .env — запусти: bash run.sh init"
    ok "Всё на месте. Можно делать: bash run.sh up"
    ;;

  build)
    log "Сборка Docker-образа..."
    docker compose build --no-cache
    ok "Образ собран"
    ;;

  up)
    log "Поднимаю контейнеры..."
    mkdir -p logs
    docker compose up -d --build
    ok "Запущено. Логи: bash run.sh logs"
    ;;

  down)
    log "Останавливаю контейнеры..."
    docker compose down
    ok "Остановлено"
    ;;

  restart)
    log "Перезапускаю ebla..."
    docker compose restart ebla
    ok "Перезапущено"
    ;;

  logs)
    log "Логи (Ctrl+C для выхода)..."
    docker compose logs -f --tail=100
    ;;

  shell)
    log "Вхожу в контейнер ebla-share..."
    docker exec -it ebla-share /bin/bash
    ;;

  clean)
    warn "Это удалит контейнеры, тома и образ. Продолжить? [y/N]"
    read -r confirm
    [ "${confirm,,}" = "y" ] || (log "Отменено" && exit 0)
    docker compose down -v --rmi local
    docker system prune -f
    ok "Очищено"
    ;;

  gradle-build)
    log "Сборка jar через Gradle Wrapper..."
    ./gradlew :ui:jar --no-daemon
    ok "Готово — смотри ui/build/libs/"
    ;;

  status)
    docker compose ps
    ;;

  *)
    err "Неизвестная команда: $CMD. Запусти 'bash run.sh help'"
    ;;
esac
