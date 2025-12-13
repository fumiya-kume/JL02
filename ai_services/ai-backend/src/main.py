from fastapi import FastAPI, File, Form, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
import os
from typing import Optional
from pydantic import BaseModel, Field
import httpx
import uvicorn
import sys
from pathlib import Path
from enum import Enum

# Add src directory to path for imports
sys.path.insert(0, str(Path(__file__).parent))

from location_db_lookup import LocationDBLookup

app = FastAPI()

# Initialize Location DB lookup
try:
    location_db = LocationDBLookup()
except FileNotFoundError as e:
    print(f"Warning: {e}")
    location_db = None


class AgeGroup(str, Enum):
    TWENTIES = "20s"
    THIRTIES_FORTIES = "30-40s"
    FIFTIES_PLUS = "50s+"
    FAMILY_WITH_KIDS = "family_with_kids"


class BudgetLevel(str, Enum):
    BUDGET = "budget"
    MID_RANGE = "mid-range"
    LUXURY = "luxury"


class TravelStyle(str, Enum):
    BACKPACKER = "backpacker"
    GUIDED_TOUR = "guided_tour"
    INDEPENDENT = "independent"
    COMFORT = "comfort"


class ActivityLevel(str, Enum):
    ACTIVE = "active"
    MODERATE = "moderate"
    RELAXED = "relaxed"


class Language(str, Enum):
    JAPANESE = "japanese"
    ENGLISH = "english"
    CHINESE = "chinese"
    KOREAN = "korean"
    SPANISH = "spanish"
    FRENCH = "french"
    GERMAN = "german"
    THAI = "thai"


class PartyType(str, Enum):
    SOLO = "solo"
    COUPLE = "couple"
    SMALL_GROUP = "small_group"
    FAMILY = "family"
    LARGE_GROUP = "large_group"


class Interest(str, Enum):
    HISTORY = "history"
    NATURE = "nature"
    ART = "art"
    FOOD = "food"
    ARCHITECTURE = "architecture"
    SHOPPING = "shopping"
    NIGHTLIFE = "nightlife"


class CuisinePreference(str, Enum):
    LOCAL = "local"
    FUSION = "fusion"
    VEGETARIAN = "vegetarian"
    STREET_FOOD = "street_food"
    FINE_DINING = "fine_dining"


class AccommodationPreference(str, Enum):
    HOTEL = "hotel"
    HOSTEL = "hostel"
    AIRBNB = "airbnb"
    RYOKAN = "ryokan"
    RESORT = "resort"


@app.get("/")
def root():
    return {"message": "Hello from AppRun + FastAPI"}


@app.get("/health")
def health():
    return {"status": "ok"}


class VLMResponse(BaseModel):
    generated_text: str
    success: bool
    error_message: Optional[str] = None


@app.post("/inference", response_model=VLMResponse)
async def vlm_inference(
    image: UploadFile = File(..., description="Image file (PNG, JPG, etc.)"),
    user_age_group: Optional[AgeGroup] = Form(
        None,
        description="Traveler's age group for marketing segmentation. Options: 20s, 30-40s, 50s+, family_with_kids",
    ),
    user_budget_level: Optional[BudgetLevel] = Form(
        None,
        description="Travel budget level affecting facility recommendations. Options: budget, mid-range, luxury",
    ),
    user_interests: Optional[list[Interest]] = Form(
        None,
        description="Categories of interest (multiple selection allowed) for attractions. Options: history, nature, art, food, architecture, shopping, nightlife",
    ),
    user_activity_level: Optional[ActivityLevel] = Form(
        None,
        description="Physical activity level for recommended activities. Options: active, moderate, relaxed",
    ),
    user_language: Language = Form(
        Language.JAPANESE,
        description="User's preferred language for guide content. Options: japanese, english, chinese, korean, spanish, french, german, thai",
    ),
    address: str = Form(
        ..., description="Address of the location where the image was taken"
    ),
    latitude: float = Form(..., description="Latitude coordinate of the location"),
    longitude: float = Form(..., description="Longitude coordinate of the location"),
    text: Optional[str] = Form(None, description="Text prompt for the image"),
    temperature: Optional[float] = Form(
        0.7,
        description="Temperature for generation (0.0-1.0, higher means more random)",
    ),
    top_p: Optional[float] = Form(
        0.99, description="Top-p value for generation (nucleus sampling threshold)"
    ),
    max_new_tokens: Optional[int] = Form(
        128, description="Maximum number of new tokens to generate"
    ),
    repetition_penalty: Optional[float] = Form(
        1.05, description="Repetition penalty (>1.0 discourages repetition)"
    ),
):
    ngrok_domain = os.getenv("NGROK_DOMAIN")
    if not ngrok_domain:
        raise HTTPException(
            status_code=500, detail="NGROK_DOMAIN environment variable not set"
        )

    image_data = await image.read()

    # もしtextが文字列型ではない場合は、補完する
    text = text or "画像中のランドマークについて、3行程度で具体的に説明してください。"

    # Location DB から top-k の観光地を検索
    top_k_spots = []
    if location_db:
        try:
            top_k_spots = location_db.find_top_k(latitude, longitude)
        except Exception as e:
            print(f"Error looking up top-k spots: {e}")

    # プロンプトを作成
    if top_k_spots:
        k_count = len(top_k_spots)
        spots_info = "\n".join(
            [f"  {i + 1}. {spot['name']}" for i, spot in enumerate(top_k_spots)]
        )
        text = (
            f"あなたは今、{address}にいます。\n"
            f"最寄りの観光地 TOP-{k_count}:\n{spots_info}\n\n"
            f"{text}"
        )
    else:
        text = f"あなたは今、{address}にいます。\n" + text
    print("text=", text)
    async with httpx.AsyncClient(timeout=300.0) as client:
        files = {"image": (image.filename, image_data, image.content_type)}
        data = {
            "text": text,
            "temperature": temperature,
            "top_p": top_p,
            "max_new_tokens": max_new_tokens,
            "repetition_penalty": repetition_penalty,
        }

        response = await client.post(
            f"https://{ngrok_domain}/inference",
            files=files,
            data=data,
        )

        if response.status_code != 200:
            raise HTTPException(
                status_code=response.status_code,
                detail="External inference service error",
            )

        result = response.json()
        return VLMResponse(
            generated_text=result.get("generated_text", ""), success=True
        )
