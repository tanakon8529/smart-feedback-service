#!/bin/bash

# Set color variables for better logging
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
BLUE="\033[0;34m"
NC="\033[0m" # No Color

# Docker compose file path
DOCKER_COMPOSE_FILE="docker-compose.yml"

run_local_test() {
  ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
  APP_IMAGE="smart-feedback-service:local"
  APP_PORT=8000
  LOG_DIR="$ROOT_DIR/.local_logs"
  mkdir -p "$LOG_DIR"

  command -v docker >/dev/null 2>&1 || { log_error "docker not found"; exit 1; }

  # 1. Build Image
  log_info "Building App image..."
  docker build -t "$APP_IMAGE" -f "$ROOT_DIR/Dockerfile" "$ROOT_DIR" || exit 1
  log_success "Built $APP_IMAGE"

  # 2. Clean up previous containers
  for c in smart-feedback-app-local smart-feedback-db-local; do
    docker rm -f "$c" >/dev/null 2>&1 || true
  done
  docker network rm smart-feedback-net >/dev/null 2>&1 || true

  # 3. Create Network
  docker network create smart-feedback-net >/dev/null

  # 4. Start DB (Dependency)
  log_info "Starting Database..."
  docker run -d --name smart-feedback-db-local \
    --network smart-feedback-net \
    -e POSTGRES_USER=user \
    -e POSTGRES_PASSWORD=password \
    -e POSTGRES_DB=feedback_db \
    postgres:15-alpine >/dev/null || { log_error "Failed to start DB"; exit 1; }
  
  # Wait for DB to be ready (Simple sleep for mock, real check preferred)
  log_info "Waiting for DB to initialize..."
  sleep 5

  # 5. Start App
  log_info "Starting App on :$APP_PORT"
  docker run -d --name smart-feedback-app-local \
    --network smart-feedback-net \
    -p $APP_PORT:8000 \
    -e DATABASE_URL=postgresql+asyncpg://user:password@smart-feedback-db-local:5432/feedback_db \
    -e ENVIRONMENT=local \
    "$APP_IMAGE" >/dev/null || { log_error "Failed to start App"; exit 1; }

  wait_200() {
    local url=$1 name=$2 timeout=${3:-60}
    local start=$(date +%s) tries=0
    while true; do
      out=$(curl -sS -o /dev/null -w "%{http_code} %{time_total}" "$url" 2>&1 || echo "000 0")
      code=${out%% *}; time=${out##* }
      tries=$((tries+1))
      if [[ "$code" == "200" ]]; then
        log_success "$name $url -> 200 in ${time}s (tries=$tries, elapsed=$(( $(date +%s)-start ))s)"
        return 0
      fi
      if (( $(date +%s)-start >= timeout )); then
        log_error "$name $url -> TIMEOUT after ${timeout}s (last=$code, tries=$tries)"
        return 1
      fi
      sleep 2
    done
  }

  log_info "Probing health endpoints (60s timeout)..."
  wait_200 "http://localhost:$APP_PORT/health" "APP" 60

  log_info "Saving logs to $LOG_DIR"
  docker logs smart-feedback-app-local > "$LOG_DIR/app.log" 2>&1 || true
  docker logs smart-feedback-db-local > "$LOG_DIR/db.log" 2>&1 || true
  log_success "Saved logs: $LOG_DIR/app.log, $LOG_DIR/db.log"

  log_info "Cleaning up local test containers..."
  docker rm -f smart-feedback-app-local smart-feedback-db-local >/dev/null 2>&1
  docker network rm smart-feedback-net >/dev/null 2>&1

  exit 0
}

# Log function with emoji
log_info() {
    echo -e "${BLUE}[ℹ️ INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✅ SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[⚠️ WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[❌ ERROR]${NC} $1"
}

# Test mode: build/run locally and probe health
if [[ "${1:-}" == "test" ]]; then
  log_info "Running local test mode..."
  run_local_test
fi

# Use local .env file for sandbox development
ENV_FILE=".env"

# Verify .env file exists
if [ ! -f "$ENV_FILE" ]; then
    log_error "Environment file not found at $ENV_FILE"
    log_error "Please create a .env file in the project root for local/sandbox development"
    exit 1
fi

log_success "Using .env for local/sandbox development"

# Load and export ENVIRONMENT variable from .env
log_info "Loading environment variables..."
export $(grep -E "^ENVIRONMENT=" .env | xargs 2>/dev/null || echo "ENVIRONMENT=local")
log_success "Environment set to: ${ENVIRONMENT:-local}"

# Check for Docker Compose v2 availability
if ! docker compose version &> /dev/null; then
    if [ -x /usr/libexec/docker/cli-plugins/docker-compose ]; then
        log_warning "docker compose plugin found but not detected by 'docker compose version'."
    else
        log_error "docker compose is not available. Please install Docker and the docker-compose plugin."
        exit 1
    fi
fi

# Check if docker-compose file exists
if [ ! -f "$DOCKER_COMPOSE_FILE" ]; then
    log_error "Docker compose file not found at $DOCKER_COMPOSE_FILE"
    exit 1
fi

# Try to shut down any running containers first, and clean dangling images
log_info "Attempting to shut down any running containers first..."
try_shutdown() {
    docker compose -f "$DOCKER_COMPOSE_FILE" down 2>/dev/null || true
    docker images -f "dangling=true" -q | xargs -r docker rmi || true

    if [ $? -eq 0 ]; then
        log_success "Successfully shut down existing containers"
    else
        log_warning "No running containers found or couldn't shut down properly"
    fi
}

# Try to start the containers
start_containers() {
    log_info "Starting containers with docker compose..."
    docker compose -f "$DOCKER_COMPOSE_FILE" up --build
    if [ $? -eq 0 ]; then
        log_success "Containers started successfully"
    else
        log_error "Failed to start containers"
        return 1
    fi
}

# Main execution with try-catch pattern
try_shutdown

# Try to start containers with error handling
log_info "🚀 Starting Smart Feedback Service..."
if ! start_containers; then
    log_error "Failed to start the application. Check the logs above for details."
    exit 1
fi
