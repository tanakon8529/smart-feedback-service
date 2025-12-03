from fastapi import FastAPI
from app.api.v1.api import api_router
from app.microservices.loader import load_microservices
from app.core.database import init_db, DBRoutingMiddleware
from app.core.queue import init_rabbit
from app.microservices.queuehealth.service import service as queue_service

app = FastAPI(
    title="Smart Feedback Analysis Service",
    description="AI-Driven Microservice for Feedback Analysis",
    version="1.0.0"
)

# Register DB Routing Middleware
app.add_middleware(DBRoutingMiddleware)

@app.on_event("startup")
async def on_startup():
    await init_db()
    await init_rabbit()
    load_microservices(app)
    app.include_router(queue_service.router, prefix=queue_service.prefix)

app.include_router(api_router, prefix="/api/v1")

@app.get("/health")
async def health_check():
    return {"status": "ok"}
