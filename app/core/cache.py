import os
from typing import Optional
from redis.asyncio import Redis

_redis: Optional[Redis] = None

def get_redis() -> Redis:
    global _redis
    if _redis is None:
        url = os.getenv("REDIS_URL", "redis://localhost:6379/0")
        _redis = Redis.from_url(url)
    return _redis

async def cache_get(key: str) -> Optional[str]:
    try:
        return await get_redis().get(key)
    except Exception:
        return None

async def cache_set(key: str, value: str, ttl: int = 60) -> None:
    try:
        await get_redis().set(key, value, ex=ttl)
    except Exception:
        pass
