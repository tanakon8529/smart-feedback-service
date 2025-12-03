import os
import json
from typing import Optional
import aio_pika

_conn: Optional[aio_pika.RobustConnection] = None
_channel: Optional[aio_pika.abc.AbstractChannel] = None
QUEUE_NAME = os.getenv("RABBIT_QUEUE", "feedback_events")

async def init_rabbit() -> None:
    global _conn, _channel
    if _conn and _channel:
        return
    url = os.getenv("RABBIT_URL", "amqp://guest:guest@localhost:5672/")
    try:
        _conn = await aio_pika.connect_robust(url)
        _channel = await _conn.channel()
        await _channel.declare_queue(QUEUE_NAME, durable=True)
    except Exception:
        _conn = None
        _channel = None

async def publish_feedback_event(payload: dict) -> bool:
    try:
        await init_rabbit()
        if not _channel:
            return False
        body = json.dumps(payload).encode()
        await _channel.default_exchange.publish(
            aio_pika.Message(body=body, content_type="application/json"), routing_key=QUEUE_NAME
        )
        return True
    except Exception:
        return False
