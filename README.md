# Smart Feedback Service

Production‑ready FastAPI service for AI‑driven feedback analysis with modular microservices, multi‑cluster DB routing, Redis cache, RabbitMQ queue, and CI/CD.

## Features
- Feedback ingestion (`POST /api/v1/feedback`) with AI classification (sentiment, category).
- Dashboard stats (`GET /api/v1/dashboard/stats`) with Redis caching.
- Dynamic microservices loader (`/services/*`) — examples: `echo`, `analyzer`, `queue` health.
- Multi‑cluster DB routing: GET→reader, writes→writer, with header overrides.
- CI/CD (mock for dev/uat/prod), auto release/tag on successful prod CI.

## Architecture
- Core modules in `app/core` (`database`, `cache`, `queue`).
- API in `app/api/v1`, microservices in `app/microservices/*` loaded dynamically.
- Dockerized stack with Postgres, Redis, RabbitMQ via `docker-compose.yml`.
- Kubernetes manifests in `k8s/` and infra scripts in `infrastructure/` (VPC/IAM/EKS).
- Full design at `plan/solution_design.md`.

## Directory Structure
- `app/` FastAPI app (API, core, microservices, services, models)
- `tests/` unit, integration, load (k6)
- `environment/` example envs and `push_secrets.sh`
- `infrastructure/` CloudShell‑ready scripts (VPC/IAM/EKS) and orchestrator
- `k8s/` deployment, service, ingress (uat/prod)
- `.github/workflows/` dev/uat/prod CI/CD and gated release
- `Dockerfile`, `docker-compose.yml`, `start.sh`, `start_and_test.sh`

## Quick Start
- Compose
  - `docker compose up -d --build`
  - Health: `http://localhost:8000/health`, Docs: `http://localhost:8000/docs`
- Script: start + tests
  - `./start_and_test.sh start` — build and start all services
  - `./start_and_test.sh test unit|integration|load|all` — run selected tests inside container
- Local test run
  - `./start.sh test` — build app image, run local DB+app, probe `/health`, save logs to `.local_logs/`

## Configuration
- Local envs use container defaults; cloud envs managed via Secrets Manager.
- Example envs: `environment/example.dev.env`, `example.uat.env`, `example.prod.env`.
- Push secrets: `AWS_REGION=us-east-1 SECRET_PREFIX=smart-feedback ./environment/push_secrets.sh dev|uat|prod|all`.

## Testing
- Unit: `pytest -q tests/unit`
- Integration (requires running app): `pytest -q tests/integration`
- Load: `k6` script in `tests/load/k6_script.js`; run via `./start_and_test.sh test load`.

## CI/CD
- Dev: mock CI — tests, mock image build, mock scans.
- UAT: mock CI/CD — tests, mock build/scan/deploy, internal ingress policy.
- Prod: mock CI/CD — tests, mock build/scan/deploy, public ingress policy.
- Release: semantic‑release runs after successful `CI/CD Prod` on `main`, creates GitHub Release and `vX.Y.Z` tag.

## Services & Endpoints
- API: `/api/v1/feedback`, `/api/v1/dashboard/stats`
- Microservices: `/services/echo/ping`, `/services/analyzer/analyze`, `/services/queue/health`

## Notes
- Pre‑push hook runs tests locally (Husky). If Docker is available, it validates in container too.
- Dynamic services mount automatically from `app/microservices/*` on startup.
