import random
import asyncio
from pydantic import BaseModel, Field
from app.models.feedback import Sentiment, Category

class FeedbackAnalysis(BaseModel):
    sentiment: Sentiment
    category: Category
    summary: str = Field(description="One sentence summary of the feedback")

class AIService:
    def __init__(self, provider: str = "mock"):
        self.provider = provider

    async def analyze_feedback(self, message: str) -> FeedbackAnalysis:
        if self.provider == "mock":
            return await self._mock_analysis(message)
        else:
            # Placeholder for Real LLM implementation (e.g., using pydantic-ai Agent)
            return await self._llm_analysis(message)

    async def _mock_analysis(self, message: str) -> FeedbackAnalysis:
        """
        Simulates an AI analysis with latency and random but plausible results.
        In a real scenario, this would be an API call to OpenAI/Claude.
        """
        await asyncio.sleep(1.0) # Simulate network latency/processing time
        
        # Simple heuristic for "better than random" mock
        lower_msg = message.lower()
        
        if any(word in lower_msg for word in ["bad", "slow", "broken", "terrible"]):
            sentiment = Sentiment.NEGATIVE
        elif any(word in lower_msg for word in ["good", "great", "fast", "love"]):
            sentiment = Sentiment.POSITIVE
        else:
            sentiment = Sentiment.NEUTRAL
            
        if "delivery" in lower_msg or "shipping" in lower_msg:
            category = Category.DELIVERY
        elif "app" in lower_msg or "website" in lower_msg or "bug" in lower_msg:
            category = Category.PRODUCT
        elif "service" in lower_msg or "support" in lower_msg:
            category = Category.SERVICE
        else:
            category = Category.OTHER

        return FeedbackAnalysis(
            sentiment=sentiment,
            category=category,
            summary=f"Customer provided feedback about {category.value} with {sentiment.value} sentiment."
        )

    async def _llm_analysis(self, message: str) -> FeedbackAnalysis:
        # TODO: Implement pydantic-ai Agent here
        # from pydantic_ai import Agent
        # agent = Agent('openai:gpt-4o', result_type=FeedbackAnalysis)
        # result = await agent.run(message)
        # return result.data
        raise NotImplementedError("Real LLM provider not configured yet.")
