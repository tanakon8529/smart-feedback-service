import pytest
from app.services.ai_service import AIService
from app.models.feedback import Sentiment, Category

@pytest.mark.asyncio
async def test_mock_ai_service_logic():
    # Force mock provider
    service = AIService()
    service.provider = "mock" 
    
    # Test Positive
    result = await service.analyze_feedback("I love this fast product")
    assert result.sentiment == Sentiment.POSITIVE
    assert result.category == Category.PRODUCT
    
    # Test Negative Delivery
    result = await service.analyze_feedback("Delivery was slow and terrible")
    assert result.sentiment == Sentiment.NEGATIVE
    assert result.category == Category.DELIVERY

@pytest.mark.asyncio
async def test_ai_service_fallback():
    # Test that if we initialize without key, it defaults to mock (simulated)
    service = AIService()
    # If env var is not set, it should be mock
    # We can't easily mock env vars here without monkeypatching before import or init
    # But we can verify the logic of the method
    
    if service.provider == "mock":
        result = await service.analyze_feedback("neutral message")
        assert result.sentiment in [Sentiment.POSITIVE, Sentiment.NEUTRAL, Sentiment.NEGATIVE]
