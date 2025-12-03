import os
import random
import asyncio
import json
import google.generativeai as genai
from pydantic import BaseModel, Field
from app.models.feedback import Sentiment, Category

class FeedbackAnalysis(BaseModel):
    sentiment: Sentiment
    category: Category
    summary: str = Field(description="One sentence summary of the feedback")

class AIService:
    def __init__(self):
        # Auto-detect provider based on API Key
        self.api_key = os.getenv("GEMINI_API_KEY")
        if self.api_key:
            self.provider = "gemini"
            genai.configure(api_key=self.api_key)
            self.model = genai.GenerativeModel('gemini-1.5-flash')
        else:
            self.provider = "mock"

    async def analyze_feedback(self, message: str) -> FeedbackAnalysis:
        if self.provider == "gemini":
            return await self._gemini_analysis(message)
        else:
            return await self._mock_analysis(message)

    async def _gemini_analysis(self, message: str) -> FeedbackAnalysis:
        """
        Analyzes feedback using Google Gemini API with structured JSON output.
        """
        prompt = f"""
        Analyze the following customer feedback and extract structured data.
        
        Feedback: "{message}"
        
        Output JSON format:
        {{
            "sentiment": "Positive" | "Neutral" | "Negative",
            "category": "Service" | "Product" | "Delivery" | "Other",
            "summary": "Concise 1-sentence summary"
        }}
        """
        
        try:
            # Run in executor to avoid blocking async loop
            response = await asyncio.to_thread(
                self.model.generate_content,
                prompt,
                generation_config={"response_mime_type": "application/json"}
            )
            
            # Parse JSON response
            data = json.loads(response.text)
            
            return FeedbackAnalysis(
                sentiment=Sentiment(data["sentiment"]),
                category=Category(data["category"]),
                summary=data["summary"]
            )
        except Exception as e:
            print(f"[AI Service Error] Gemini failed: {e}. Falling back to mock.")
            return await self._mock_analysis(message)

    async def _mock_analysis(self, message: str) -> FeedbackAnalysis:
        """
        Simulates an AI analysis with latency and random but plausible results.
        Fallback if no API Key is provided or API fails.
        """
        await asyncio.sleep(0.5) # Reduced latency for mock
        
        # Simple heuristic for "better than random" mock
        lower_msg = message.lower()
        
        if any(word in lower_msg for word in ["bad", "slow", "broken", "terrible", "worst"]):
            sentiment = Sentiment.NEGATIVE
        elif any(word in lower_msg for word in ["good", "great", "fast", "love", "best"]):
            sentiment = Sentiment.POSITIVE
        else:
            sentiment = Sentiment.NEUTRAL
            
        if "delivery" in lower_msg or "shipping" in lower_msg or "late" in lower_msg:
            category = Category.DELIVERY
        elif (
            "product" in lower_msg or "feature" in lower_msg or "quality" in lower_msg
            or "app" in lower_msg or "website" in lower_msg or "bug" in lower_msg or "crash" in lower_msg
        ):
            category = Category.PRODUCT
        elif "service" in lower_msg or "support" in lower_msg or "rude" in lower_msg:
            category = Category.SERVICE
        else:
            category = Category.OTHER

        return FeedbackAnalysis(
            sentiment=sentiment,
            category=category,
            summary=f"[Mock Analysis] Customer provided feedback about {category.value}."
        )
