# Smart Feedback Service – Timeline Story

## Phase 1: Foundation and Design
- Solution design authored with architecture for AWS multi-scale microservices, VPC, ALB/API Gateway with OAuth2, EKS, CloudWatch streaming, DynamoDB/vector DB RAG, and AI orchestration.
- Initial FastAPI service scaffolded with Pydantic models and core modules.

## Phase 2: Startup and Performance Runtime
- Added `start.sh` adapted to project; validated environment and container management.
- Migrated runtime to Granian (Rust-based) and package management to `uv` for speed.
- Fixed Granian flags (`--interface asgi`, removed invalid `--workers auto`, ensured `granian[reload]`).
- Verified health endpoint and container startup.

## Phase 3: Database Multi‑Cluster Routing
- Refactored `app/core/database.py` to add `DBManager` and `DBRoutingMiddleware`.
- Implemented GET→reader, POST→writer routing with header overrides and context-aware sessions.
- Registered middleware in `app/main.py`.

## Phase 4: AI Integration
- Integrated Google Gemini API with JSON-mode output and robust mock fallback in `app/services/ai_service.py`.
- Improved mock categorization for “product/feature/quality/app/website/bug/crash”.

## Phase 5: Testing Strategy
- Restructured `tests/` into unit, integration, and load (k6) categories.
- Implemented unit tests for models/services and integration tests for API.
- Added k6 script with staged VUs and thresholds.

## Phase 6: Unified Start & Test Script
- Created `start_and_test.sh` to start services and run selected tests (unit/integration/load/all) with health wait and k6 execution (Dockerized).

## Phase 7: Docker Build Caching
- Optimized `Dockerfile` to copy `requirements.txt` first and cache `uv` installs via BuildKit cache mount.
- Verified faster rebuilds when deps unchanged.

## Phase 8: Integration Test Reliability
- Updated `tests/conftest.py` to use `AsyncClient` over network for integration, avoiding ASGI transport loop conflicts.
- Normalized enum keys to strings in dashboard stats.

## Phase 9: Infrastructure Scripts (CloudShell‑ready)
- Added `infrastructure/vpc/create_vpc.sh` to provision VPC, subnets, IGW, NAT, route tables.
- Added `infrastructure/iam/create_roles.sh` for EKS cluster/node roles and policies.
- Added `infrastructure/eks/create_eks_cluster.sh` (installs `eksctl` if absent), creates managed node group, enables logging.
- Orchestrator `infrastructure/set-up.sh` to run VPC→IAM→EKS.

## Phase 10: Environment and Secrets
- Added `environment/example.dev.env`, `example.uat.env`, `example.prod.env` templates.
- Implemented `environment/push_secrets.sh` to push envs to AWS Secrets Manager (fallback to example files if real envs missing).
- Updated `.gitignore` to keep examples, ignore real envs; removed real env files from repo.

## Phase 11: Husky Quality Gate
- Added Husky with `pre-push` hook running unit/integration tests locally and optionally in Docker.
- Improved hook to wait for server health and execute tests in container.

## Phase 12: Modular Microservices
- Introduced dynamic microservice loader: `app/microservices/loader.py`.
- Sample `echo` microservice (`/services/echo/ping`) and analyzer microservice (`/services/analyzer/analyze`).
- Added integration tests for dynamic services.

## Phase 13: CI/CD Pipelines
- Added GitHub Actions:
  - Dev: mock CI with tests and mock scans; no deploy.
  - UAT: mock CI/CD with tests, mock build/scan/deploy, ingress exposure checks (internal policy).
  - Prod: mock CI/CD with tests, mock build/scan/deploy, ingress exposure checks (public policy).
- Added Kubernetes manifests (`k8s/deployment.yaml`, `k8s/service.yaml`, `k8s/ingress-uat.yaml`, `k8s/ingress-prod.yaml`).

## Phase 14: Caching and Messaging
- Integrated Redis (`app/core/cache.py`) for caching dashboard stats.
- Integrated RabbitMQ (`app/core/queue.py`) for publishing feedback events; init on startup.
- Added queue health microservice (`/services/queue/health`).

## Phase 15: Auto Release and Tagging
- Implemented automatic release gated by successful Prod CI.
- Initially tried Release Please; resolved manifest error; later refactored to `semantic-release`.
- Final release workflow uses semantic-release to generate notes, tags (`vX.Y.Z`), and GitHub Releases (after Prod CI success).

## Phase 16: CI Stabilization
- Fixed `ModuleNotFoundError: app` in CI by setting `PYTHONPATH=$GITHUB_WORKSPACE`.
- Removed fragile `secrets.*` conditions from workflows; kept mock behavior robust.
- Skipped integration tests in mock CI to avoid dependency on running server.

## Current Status
- Service runs locally with Granian+uv, multi-cluster DB routing, Gemini AI integration, Redis caching, RabbitMQ messaging, dynamic microservices.
- Tests green locally; CI workflows stabilized in mock mode across dev/uat/prod.
- Auto release/tagging configured to publish after successful Prod CI on `main`.
