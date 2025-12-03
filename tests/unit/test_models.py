import pytest
from pydantic import ValidationError
from app.models.feedback import FeedbackCreate, Sentiment, Category

def test_feedback_model_valid():
    feedback = FeedbackCreate(customer_id="123", message="Great service")
    assert feedback.customer_id == "123"
    assert feedback.message == "Great service"

def test_feedback_model_invalid_missing_field():
    with pytest.raises(ValidationError):
        FeedbackCreate(customer_id="123") # Missing message

def test_enums():
    assert Sentiment.POSITIVE == "Positive"
    assert Category.SERVICE == "Service"
