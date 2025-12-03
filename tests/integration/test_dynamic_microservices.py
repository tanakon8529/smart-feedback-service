import pytest

@pytest.mark.asyncio
async def test_echo_microservice(client):
    r = await client.get("/services/echo/ping")
    assert r.status_code == 200
    data = r.json()
    assert data["service"] == "echo"
    assert data["status"] == "ok"
