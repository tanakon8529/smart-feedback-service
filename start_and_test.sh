#!/bin/bash

GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
BLUE="\033[0;34m"
NC="\033[0m"

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_ok() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_err() { echo -e "${RED}[ERR]${NC} $1"; }

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
COMPOSE_FILE="$ROOT_DIR/docker-compose.yml"

require_docker() { command -v docker >/dev/null 2>&1 || { log_err "docker not found"; exit 1; }; }
require_compose() { docker compose version >/dev/null 2>&1 || { log_err "docker compose not available"; exit 1; }; }
require_compose_file() { [ -f "$COMPOSE_FILE" ] || { log_err "docker-compose.yml missing"; exit 1; }; }

up() {
  require_docker; require_compose; require_compose_file
  log_info "Starting containers detached"
  docker compose -f "$COMPOSE_FILE" up -d --build || { log_err "compose up failed"; exit 1; }
  log_ok "Containers up"
}

down() {
  require_docker; require_compose; require_compose_file
  log_info "Stopping containers"
  docker compose -f "$COMPOSE_FILE" down || { log_err "compose down failed"; exit 1; }
  log_ok "Containers stopped"
}

wait_health() {
  local url=${1:-"http://localhost:8000/health"}
  local timeout=${2:-60}
  local start=$(date +%s)
  while true; do
    code=$(curl -sS -o /dev/null -w "%{http_code}" "$url" || echo "000")
    if [ "$code" = "200" ]; then log_ok "Health 200"; return 0; fi
    [ $(( $(date +%s)-start )) -ge $timeout ] && { log_err "Health timeout"; return 1; }
    sleep 2
  done
}

run_pytest() {
  local path=$1
  docker compose -f "$COMPOSE_FILE" exec -T web python -m pytest "$path" || exit 1
}

run_k6() {
  require_docker
  local script="$ROOT_DIR/tests/load/k6_script.js"
  [ -f "$script" ] || { log_err "k6 script missing"; exit 1; }
  local os=$(uname -s)
  local base_url="http://localhost:8000"
  local extra=""
  if [ "$os" = "Darwin" ]; then
    base_url="http://host.docker.internal:8000"
  else
    extra="--network host"
  fi
  tmpfile=$(mktemp)
  sed "s#http://localhost:8000#$base_url#g" "$script" > "$tmpfile"
  docker run --rm $extra -v "$tmpfile:/script.js:ro" grafana/k6:latest run /script.js || { rm -f "$tmpfile"; exit 1; }
  rm -f "$tmpfile"
}

prompt_select() {
  echo "Select tests: [unit|integration|load|all]"
  read -r choice
  case "$choice" in
    unit) test_unit ;;
    integration) test_integration ;;
    load) test_load ;;
    all) test_all ;;
    *) log_err "invalid selection"; exit 1 ;;
  esac
}

test_unit() { up; run_pytest tests/unit; }
test_integration() { up; wait_health; run_pytest tests/integration; }
test_all() { up; wait_health; run_pytest tests; }
test_load() { up; wait_health; run_k6; }

case "${1:-}" in
  start) up ;;
  stop) down ;;
  test)
    case "${2:-}" in
      unit) test_unit ;;
      integration) test_integration ;;
      load) test_load ;;
      all) test_all ;;
      *) prompt_select ;;
    esac
    ;;
  *)
    echo "Usage: $0 start|stop|test [unit|integration|load|all]"
    exit 1
    ;;
esac

