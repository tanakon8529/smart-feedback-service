from fastapi import APIRouter
from app.core.queue import init_rabbit

router = APIRouter()

@router.get("/health")
async def health():
    await init_rabbit()
    return {"queue": "ok"}

class QueueHealthService:
    name = "queue"
    prefix = "/services/queue"
    router = router

service = QueueHealthService()
