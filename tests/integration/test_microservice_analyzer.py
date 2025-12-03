import pytest

@pytest.mark.asyncio
async def test_analyzer_microservice_negative_delivery(client):
    payload = {"message": "The delivery was terrible and slow."}
    r = await client.post("/services/analyzer/analyze", json=payload)
    assert r.status_code == 200
    data = r.json()
    assert data["sentiment"] == "Negative"
    assert data["category"] == "Delivery"

@pytest.mark.asyncio
async def test_analyzer_microservice_positive_product(client):
    payload = {"message": "Great product quality and fast app!"}
    r = await client.post("/services/analyzer/analyze", json=payload)
    assert r.status_code == 200
    data = r.json()
    assert data["sentiment"] == "Positive"
    assert data["category"] == "Product"
