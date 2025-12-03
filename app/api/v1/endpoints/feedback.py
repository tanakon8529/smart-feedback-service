from fastapi import APIRouter, Depends, HTTPException
from sqlmodel.ext.asyncio.session import AsyncSession
from sqlalchemy import func, select
from app.core.database import get_session
from app.models.feedback import Feedback, FeedbackCreate, FeedbackRead, Category, Sentiment
from app.services.ai_service import AIService
from app.core.cache import cache_get, cache_set
from app.core.queue import publish_feedback_event

router = APIRouter()
ai_service = AIService()

@router.post("/feedback", response_model=FeedbackRead, status_code=201)
async def create_feedback(
    feedback_in: FeedbackCreate,
    session: AsyncSession = Depends(get_session)
):
    """
    Ingest customer feedback and process it with AI (Mock/LLM).
    """
    # 1. Analyze with AI
    analysis = await ai_service.analyze_feedback(feedback_in.message)
    
    # 2. Create DB Object
    feedback = Feedback(
        customer_id=feedback_in.customer_id,
        message=feedback_in.message,
        sentiment=analysis.sentiment,
        category=analysis.category,
        summary=analysis.summary
    )
    
    # 3. Save to DB
    session.add(feedback)
    await session.commit()
    await session.refresh(feedback)
    await publish_feedback_event({
        "id": feedback.id,
        "customer_id": feedback.customer_id,
        "sentiment": feedback.sentiment.value if feedback.sentiment else None,
        "category": feedback.category.value if feedback.category else None,
    })
    
    return feedback

@router.get("/dashboard/stats")
async def get_dashboard_stats(session: AsyncSession = Depends(get_session)):
    """
    Get aggregated statistics for feedback.
    Optimized for performance using database-level aggregation.
    """
    # Try cache first
    cached = await cache_get("dashboard_stats")
    if cached:
        import json
        return json.loads(cached)

    # Optimized Queries: Group by Category
    cat_query = select(Feedback.category, func.count(Feedback.id)).group_by(Feedback.category)
    cat_result = await session.exec(cat_query)
    category_stats = {
        (row[0].value if isinstance(row[0], Category) else row[0]): row[1]
        for row in cat_result.all() if row[0] is not None
    }
    
    # Optimized Queries: Group by Sentiment
    sent_query = select(Feedback.sentiment, func.count(Feedback.id)).group_by(Feedback.sentiment)
    sent_result = await session.exec(sent_query)
    sentiment_stats = {
        (row[0].value if isinstance(row[0], Sentiment) else row[0]): row[1]
        for row in sent_result.all() if row[0] is not None
    }
    
    # Total Count
    total_query = select(func.count(Feedback.id))
    total_result = await session.exec(total_query)
    total_count = total_result.scalar_one()
    
    result = {
        "total_feedback": total_count,
        "by_category": category_stats,
        "by_sentiment": sentiment_stats
    }
    import json
    await cache_set("dashboard_stats", json.dumps(result), ttl=60)
    return result
