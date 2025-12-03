import pytest
from redis.asyncio import Redis

@pytest.mark.asyncio
async def test_dashboard_stats_cached(client):
    r = await client.get("/api/v1/dashboard/stats")
    assert r.status_code == 200
    redis = Redis.from_url("redis://redis:6379/0")
    val = await redis.get("dashboard_stats")
    assert val is not None

@pytest.mark.asyncio
async def test_queue_health(client):
    r = await client.get("/services/queue/health")
    assert r.status_code == 200
    assert r.json().get("queue") == "ok"
