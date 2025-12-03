from datetime import datetime
from enum import Enum
from typing import Optional
from sqlmodel import Field, SQLModel

class Sentiment(str, Enum):
    POSITIVE = "Positive"
    NEUTRAL = "Neutral"
    NEGATIVE = "Negative"

class Category(str, Enum):
    SERVICE = "Service"
    PRODUCT = "Product"
    DELIVERY = "Delivery"
    OTHER = "Other"

class FeedbackBase(SQLModel):
    customer_id: str = Field(index=True)
    message: str

class Feedback(FeedbackBase, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    sentiment: Optional[Sentiment] = Field(default=None, index=True)
    category: Optional[Category] = Field(default=None, index=True)
    summary: Optional[str] = Field(default=None)
    created_at: datetime = Field(default_factory=datetime.utcnow, index=True)

class FeedbackCreate(FeedbackBase):
    pass

class FeedbackRead(FeedbackBase):
    id: int
    sentiment: Optional[Sentiment]
    category: Optional[Category]
    summary: Optional[str]
    created_at: datetime
