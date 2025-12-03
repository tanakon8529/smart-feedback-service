from fastapi import APIRouter

router = APIRouter()

@router.get("/ping")
async def ping():
    return {"service": "echo", "status": "ok"}

class EchoService:
    name = "echo"
    prefix = "/services/echo"
    router = router

service = EchoService()
