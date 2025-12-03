import pytest
from app.models.feedback import Sentiment, Category

@pytest.mark.asyncio
async def test_create_feedback(client):
    payload = {
        "customer_id": "cust_001",
        "message": "I love this product, it is so fast and good!"
    }
    response = await client.post("/api/v1/feedback", json=payload)
    assert response.status_code == 201
    data = response.json()
    print("NEG_FEEDBACK_DATA:", data)
    assert data["customer_id"] == "cust_001"
    assert data["sentiment"] == "Positive"
    assert data["category"] == "Product"
    assert "summary" in data

@pytest.mark.asyncio
async def test_create_negative_feedback(client):
    payload = {
        "customer_id": "cust_002",
        "message": "The delivery was terrible and slow."
    }
    response = await client.post("/api/v1/feedback", json=payload)
    assert response.status_code == 201
    data = response.json()
    assert data["sentiment"] == "Negative"
    assert data["category"] == "Delivery"

@pytest.mark.asyncio
async def test_dashboard_stats(client):
    # We already added 2 feedbacks in previous tests
    response = await client.get("/api/v1/dashboard/stats")
    assert response.status_code == 200
    data = response.json()
    print("DASHBOARD_STATS:", data)
    
    assert data["total_feedback"] >= 2
    assert data["by_sentiment"]["Positive"] >= 1
    assert data["by_sentiment"]["Negative"] >= 1
    assert data["by_category"]["Product"] >= 1
    assert data["by_category"]["Delivery"] >= 1
