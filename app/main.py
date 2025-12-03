from fastapi import FastAPI
from app.api.v1.api import api_router
from app.core.database import init_db

app = FastAPI(
    title="Smart Feedback Analysis Service",
    description="AI-Driven Microservice for Feedback Analysis",
    version="1.0.0"
)

@app.on_event("startup")
async def on_startup():
    await init_db()

app.include_router(api_router, prefix="/api/v1")

@app.get("/health")
async def health_check():
    return {"status": "ok"}
