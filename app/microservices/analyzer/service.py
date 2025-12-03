from fastapi import APIRouter
from pydantic import BaseModel
from app.services.ai_service import AIService

router = APIRouter()

class AnalysisRequest(BaseModel):
    message: str

ai = AIService()

@router.post("/analyze")
async def analyze(req: AnalysisRequest):
    result = await ai.analyze_feedback(req.message)
    return result

class AnalyzerService:
    name = "analyzer"
    prefix = "/services/analyzer"
    router = router

service = AnalyzerService()
