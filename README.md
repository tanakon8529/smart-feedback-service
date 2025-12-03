# Smart Feedback Analysis Service

A high-performance, AI-driven microservice for analyzing customer feedback.

## 🎯 Challenge Overview
- **Objective**: Build a Feedback Analysis Service with AI capabilities.
- **Tech Stack**: Python (FastAPI), PostgreSQL, PydanticAI, Docker.
- **Time Limit**: 4 Hours.

## 🚀 Features
1.  **Feedback Ingestion (`POST /api/v1/feedback`)**:
    -   Accepts JSON feedback.
    -   Uses AI (Mock/LLM) to analyze Sentiment and Category.
    -   Saves result to Database.
2.  **Dashboard Stats (`GET /api/v1/dashboard/stats`)**:
    -   Returns aggregated statistics.
    -   Optimized SQL queries for performance.

## 🛠️ Architecture & Design
See full design document at [plan/solution_design.md](plan/solution_design.md).
- **Cloud-Native**: Designed for AWS EKS.
- **Scalable**: Split into Ingestion, Worker, and Dashboard services (simulated here in one app).

## 📦 Installation & Running

### Prerequisites
- Docker & Docker Compose

### Run with Docker
```bash
docker-compose up --build
```
The API will be available at `http://localhost:8000`.
- Docs: `http://localhost:8000/docs`

### Run Tests
```bash
# Inside the container or local env
pytest
```

## 🤖 AI Usage Log
See [AI_LOG.md](AI_LOG.md) for details on how AI was used to build this project.

## 📝 Deliverables
- Source Code: `app/`
- Tests: `tests/`
- Docker: `docker-compose.yml`, `Dockerfile`
- Design: `plan/solution_design.md`
