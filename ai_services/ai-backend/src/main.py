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
import json

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


def build_rag_query_prompt(
    caption: str,
    address: str,
    user_age_group: Optional[str],
    user_budget_level: Optional[str],
    user_interests: Optional[list[str]],
    user_activity_level: Optional[str],
    user_language: Optional[str] = None,
) -> str:
    """
    Build a RAG query prompt based on VLM caption and user attributes.
    The query is designed to retrieve relevant tourism guide information with
    structured output including facility name and description.
    """
    prompt = f"写真の場所: {address}\n"
    prompt += f"写真の説明: {caption}\n\n"

    # Build user profile context
    profile_parts = []
    if user_age_group:
        profile_parts.append(f"年齢層: {user_age_group}")
    if user_budget_level:
        profile_parts.append(f"予算: {user_budget_level}")
    if user_interests:
        interests_str = ", ".join(user_interests)
        profile_parts.append(f"興味: {interests_str}")
    if user_activity_level:
        profile_parts.append(f"活動レベル: {user_activity_level}")

    if profile_parts:
        prompt += "ユーザー属性:\n"
        for part in profile_parts:
            prompt += f"  - {part}\n"
        prompt += "\n"

    prompt += (
        "上記の場所について、以下の形式で回答してください:\n\n"
        "【施設/場所の名前】\n"
        "[ここに施設や場所の正式名称を記入]\n\n"
        "【観光ガイド情報】\n"
        "[ユーザーの属性にパーソナライズした3行程度の情報。"
        "以下を含めてください:\n"
        "- 場所の概要\n"
        "- ユーザーの興味や予算に合わせた見どころ\n\n(notion!)もし観光地や施設が不明であれば、ユーザーの属性に応じて画像の説明を2行で説明を行ってください]\n"
    )

    # Add language instruction if specified
    if user_language and user_language != "japanese":
        language_map = {
            "english": "English",
            "chinese": "Chinese",
            "korean": "Korean",
            "spanish": "Spanish",
            "french": "French",
            "german": "German",
            "thai": "Thai",
        }
        lang_name = language_map.get(user_language, user_language)
        prompt += f"\n\n回答は{lang_name}で提供してください。"

    return prompt


def is_facility_name_unknown(facility_name: str) -> bool:
    """
    Check if facility name indicates unknown facility across multiple languages.

    Returns True if facility name contains indicators like "不明", "Unknown", "未知", etc.
    This handles cases where RAG returns facility names that explicitly indicate
    the facility is unrecognized, allowing fallback to address instead.

    Args:
        facility_name: The extracted facility name from RAG response

    Returns:
        True if facility name contains unknown indicators, False otherwise
    """
    # Japanese: 不明, 詳細不明, 不詳, 未確認, 未定義
    # English: Unknown, Unspecified, Not specified, Unclear, Not identified, Not determined
    # Chinese: 未知, 不清楚, 不明, 未确定, 不详, 未定义
    # Korean: 불명, 미상, 미정, 상세불명, 미확인, 미정의
    # Spanish: Desconocido, No especificado, No identificado, Indeterminado
    # French: Inconnu, Non spécifié, Indéterminé, Non identifié
    # German: Unbekannt, Nicht angegeben, Unidentifiziert, Nicht bestimmt
    # Thai: ไม่ทราบ, ไม่ชัดเจน, ไม่ระบุ, ยังไม่ได้กำหนด
    unknown_indicators = [
        # Japanese
        "不明", "詳細不明", "不詳", "未確認", "未定義",
        # English
        "unknown", "unspecified", "not specified", "unclear", "not identified", "not determined",
        # Chinese
        "未知", "不清楚", "未确定", "不详", "未定义",
        # Korean
        "불명", "미상", "미정", "상세불명", "미확인", "미정의",
        # Spanish
        "desconocido", "no especificado", "no identificado", "indeterminado",
        # French
        "inconnu", "non spécifié", "indéterminé", "non identifié",
        # German
        "unbekannt", "nicht angegeben", "unidentifiziert", "nicht bestimmt",
        # Thai
        "ไม่ทราบ", "ไม่ชัดเจน", "ไม่ระบุ", "ยังไม่ได้กำหนด",
    ]
    # Case-insensitive search for mixed-case indicators (English, Spanish, French, German)
    facility_name_lower = facility_name.lower()
    return any(indicator.lower() in facility_name_lower for indicator in unknown_indicators)


async def query_rag(
    api_token: str,
    query: str,
    top_k: int = 3,
    threshold: float = 0.3,
) -> Optional[dict]:
    """
    Query the Sakura AI Engine RAG API.

    Args:
        api_token: API token for authentication
        query: Query string
        top_k: Number of top results to retrieve
        threshold: Similarity threshold for filtering results

    Returns:
        Response JSON containing answer and sources, or None if error
    """
    url = "https://api.ai.sakura.ad.jp/v1/documents/chat/"

    payload = {
        "model": "multilingual-e5-large",
        "chat_model": "gpt-oss-120b",
        "query": query,
        "top_k": top_k,
        "threshold": threshold,
    }

    try:
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.post(
                url,
                json=payload,
                headers={
                    "Authorization": f"Bearer {api_token}",
                    "Content-Type": "application/json",
                    "Accept": "application/json",
                },
            )

            if response.status_code == 200:
                return response.json()
            else:
                print(f"RAG API error: Status {response.status_code}")
                print(f"Response: {response.text}")
                return None
    except httpx.TimeoutException as e:
        print(f"RAG API timeout: {e}")
        return None
    except httpx.RequestError as e:
        print(f"RAG API request error: {e}")
        return None


def parse_rag_response(rag_answer: str, address: str = "") -> tuple[str, str]:
    """
    Parse RAG response with structured format to extract facility name and description.

    Expected format:
    【施設/場所の名前】
    [facility name]

    【観光ガイド情報】
    [guide content]

    Args:
        rag_answer: Raw answer text from RAG API
        address: Address to use as fallback when facility name is unrecognized

    Returns:
        Tuple of (facility_name, guide_description).
        Uses address as fallback if:
        - Facility name is not extracted from response
        - Facility name contains unknown indicators (e.g., "不明", "詳細不明")
        If all parsing fails, returns (address or "Unknown Facility", full answer)
    """
    facility_name = ""
    guide_description = ""

    try:
        # Try to extract facility name
        name_start = rag_answer.find("【施設/場所の名前】")
        if name_start != -1:
            name_start += len("【施設/場所の名前】")
            name_end = rag_answer.find("【観光ガイド情報】", name_start)
            if name_end == -1:
                name_end = len(rag_answer)
            facility_name = rag_answer[name_start:name_end].strip()

        # Try to extract guide description
        guide_start = rag_answer.find("【観光ガイド情報】")
        if guide_start != -1:
            guide_start += len("【観光ガイド情報】")
            guide_description = rag_answer[guide_start:].strip()

        # If parsing succeeded, check if facility name is valid (not "不明", etc.)
        if facility_name and guide_description:
            if is_facility_name_unknown(facility_name):
                print(f"Facility name indicates unknown facility ('{facility_name}'), using address as fallback")
                return address or "Unknown Facility", guide_description
            else:
                print(f"Parsed facility name: {facility_name}")
                return facility_name, guide_description

        # If only guide description was found, use address as facility name
        if guide_description:
            print("Facility name not recognized, using address as fallback")
            return address or "Unknown Facility", guide_description

        # Fallback: use address if no structure found
        print("No structured format found in RAG response, using address as fallback")
        return address or "Unknown Facility", rag_answer

    except Exception as e:
        print(f"Error parsing RAG response: {e}")
        return address or "Unknown Facility", rag_answer


class VLMAgentResponse(BaseModel):
    """
    Response model for VLM inference with RAG-enhanced tourism guide generation.

    This model encapsulates the output from the vision-language model (VLM) inference
    combined with retrieval-augmented generation (RAG) for personalized tourism guides.

    Processing Flow:
    1. Image is sent to VLM API with location context and optional custom prompt
    2. VLM returns facility description/caption
    3a. If text parameter is None: RAG processes the caption with user attributes
        - Recognizable facility: Returns facility name + 3-line personalized guide
        - Unknown facility: Returns address as facility name + 2-line description (image explanation)
    3b. If text parameter is provided: RAG is skipped
        - Returns address as facility name
        - Returns raw VLM analysis

    Response Content Varies By Mode & Facility Recognition:
    - RAG Mode + Known Facility (text=None): Personalized 3-line tourism guide
    - RAG Mode + Unknown Facility (text=None): 2-line image description with user preferences
    - VLM Mode (text provided): Raw facility analysis based on custom prompt
    """

    name: str = Field(
        ...,
        description="Facility or place name. "
        "When text is None (RAG mode): Official facility name extracted from RAG response. "
        "If facility is unrecognized, falls back to the provided address. "
        "When text is provided (VLM mode): Address provided as facility name. "
        "Fallback value is 'Unknown Facility' only if address is not provided.",
        example="東京タワー",
    )
    facility_description: str = Field(
        ...,
        description="Generated content based on processing mode and facility recognition. "
        "RAG Mode - Known Facility (text=None): Personalized 3-line tourism guide covering overview "
        "and highlights matching user interests/budget. "
        "RAG Mode - Unknown Facility (text=None): 2-line image description personalized for user attributes. "
        "VLM Mode (text provided): Raw facility analysis from VLM without RAG processing.",
        example="東京タワーは、1958年建設の333mランドマーク。建築好きに最適で、中層展望台(¥900-1100)からの関東平野の眺望が素晴らしい。"
        "晴天時がおすすめ。赤坂見附駅・神谷町駅から利便性が高い。",
    )
    success: bool = Field(
        ...,
        description="Whether the VLM inference and (if applicable) RAG generation was successful. "
        "Returns true even if facility is unrecognized (falls back to image description) "
        "or if RAG fails (falls back to VLM output).",
        example=True,
    )
    error_message: Optional[str] = Field(
        None,
        description="Error message if inference or generation failed. None on success.",
        example=None,
    )


@app.post(
    "/inference",
    response_model=VLMAgentResponse,
    summary="VLM-based Tourism Guide Generation with RAG",
    description="Infers facility information from an image using Vision-Language Model (VLM) "
    "and generates personalized tourism guides using Retrieval-Augmented Generation (RAG). "
    "When text parameter is omitted, RAG generates personalized 3-line tourism guide for recognized facilities, "
    "or 2-line image description for unknown facilities, both customized to user attributes. "
    "When text parameter is provided, returns raw VLM analysis without RAG processing.",
    tags=["inference"],
)
async def vlm_inference(
    image: UploadFile = File(..., description="Image file containing a landmark or facility (PNG, JPG, etc.)"),
    user_age_group: Optional[AgeGroup] = Form(
        None,
        description="Traveler's age group for personalizing recommendations. "
        "Options: 20s, 30-40s, 50s+, family_with_kids. Used for RAG guide generation.",
    ),
    user_budget_level: Optional[BudgetLevel] = Form(
        None,
        description="Travel budget level affecting facility and dining recommendations. "
        "Options: budget, mid-range, luxury. Used for RAG guide generation.",
    ),
    user_interests: Optional[list[Interest]] = Form(
        None,
        description="Categories of interest for personalizing attractions and recommendations. "
        "Multiple selection allowed. Options: history, nature, art, food, architecture, shopping, nightlife. "
        "Used for RAG guide generation.",
    ),
    user_activity_level: Optional[ActivityLevel] = Form(
        None,
        description="Physical activity level for recommending activities. "
        "Options: active, moderate, relaxed. Used for RAG guide generation.",
    ),
    user_language: Language = Form(
        Language.JAPANESE,
        description="User's preferred language for guide content. "
        "Options: japanese, english, chinese, korean, spanish, french, german, thai. "
        "Affects RAG-generated guide output language.",
    ),
    address: str = Form(
        ..., description="Address of the location where the image was taken. "
        "Used in VLM prompt context and returned as name when text parameter is provided."
    ),
    latitude: float = Form(..., description="Latitude coordinate of the location. Used for nearby attraction lookup."),
    longitude: float = Form(..., description="Longitude coordinate of the location. Used for nearby attraction lookup."),
    text: Optional[str] = Form(
        None,
        description="Optional custom text prompt for VLM analysis. "
        "If omitted (None): Uses default prompt and applies RAG for personalized 3-line tourism guide. "
        "If provided: Uses custom prompt and returns raw VLM output without RAG processing. "
        "This allows flexibility between personalized guides and custom analysis."
    ),
    temperature: Optional[float] = Form(
        0.7,
        description="Temperature for VLM generation (0.0-1.0). Higher values increase randomness. Used in VLM API calls only.",
    ),
    top_p: Optional[float] = Form(
        0.99, description="Top-p value for VLM generation (nucleus sampling threshold). Used in VLM API calls only."
    ),
    max_new_tokens: Optional[int] = Form(
        128, description="Maximum number of tokens for VLM generation. Used in VLM API calls only."
    ),
    repetition_penalty: Optional[float] = Form(
        1.05, description="Repetition penalty for VLM generation (>1.0 discourages repetition). Used in VLM API calls only."
    ),
):
    ngrok_domain = os.getenv("NGROK_DOMAIN")
    if not ngrok_domain:
        raise HTTPException(
            status_code=500, detail="NGROK_DOMAIN environment variable not set"
        )

    sakura_token = os.getenv("SAKURA_OPENAI_API_TOKEN")
    if not sakura_token:
        raise HTTPException(
            status_code=500,
            detail="SAKURA_OPENAI_API_TOKEN environment variable not set",
        )

    image_data = await image.read()

    # VLMの呼び出し用テキストを準備
    vlm_prompt = text or "画像中のランドマークについて、3行程度で具体的に説明してください。"

    # Location DB から top-k の観光地を検索
    top_k_spots = []
    if location_db:
        try:
            top_k_spots = location_db.find_top_k(latitude, longitude)
        except Exception as e:
            print(f"Error looking up top-k spots: {e}")

    # VLM用プロンプトを作成
    if top_k_spots:
        k_count = len(top_k_spots)
        spots_info = "\n".join(
            [f"  {i + 1}. {spot['name']}" for i, spot in enumerate(top_k_spots)]
        )
        vlm_prompt = (
            f"あなたは今、{address}にいます。\n"
            f"最寄りの観光地 TOP-{k_count}:\n{spots_info}\n\n"
            f"{vlm_prompt}"
        )
    else:
        vlm_prompt = f"あなたは今、{address}にいます。\n" + vlm_prompt
    print("VLM Prompt:", vlm_prompt)

    async with httpx.AsyncClient(timeout=300.0) as client:
        files = {"image": (image.filename, image_data, image.content_type)}
        data = {
            "text": vlm_prompt,
            "temperature": temperature,
            "top_p": top_p,
            "max_new_tokens": max_new_tokens,
            "repetition_penalty": repetition_penalty,
        }

        # VLM APIの呼び出し
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

        vlm_result = response.json()
        vlm_caption = vlm_result.get("generated_text", "")

        # ユーザーがカスタムテキスト指示を入力している場合はRAGをスキップ
        if text is not None:
            print("Custom text instruction provided, skipping RAG")
            return VLMAgentResponse(
                name=address,
                facility_description=vlm_caption,
                success=True,
                error_message=None,
            )

        # textがNoneの場合(デフォルトプロンプト)はRAG処理を実行
        print("Using RAG for tourism guide generation")

        # RAGクエリプロンプトを構築
        rag_query = build_rag_query_prompt(
            caption=vlm_caption,
            address=address,
            user_age_group=user_age_group.value if user_age_group else None,
            user_budget_level=user_budget_level.value if user_budget_level else None,
            user_interests=[interest.value for interest in user_interests]
            if user_interests
            else None,
            user_activity_level=user_activity_level.value
            if user_activity_level
            else None,
            user_language=user_language.value,
        )

        print("RAG Query:", rag_query)

        # RAG APIを呼び出し
        rag_response = await query_rag(sakura_token, rag_query)

        if rag_response and "answer" in rag_response:
            guide_text = rag_response["answer"]
            # Parse RAG response to extract facility name and description
            # Use address as fallback for facility name when facility is unrecognized
            facility_name, facility_description = parse_rag_response(guide_text, address)
            return VLMAgentResponse(
                name=facility_name,
                facility_description=facility_description,
                success=True,
                error_message=None,
            )
        else:
            # RAGが失敗した場合はVLMの出力を返す
            print("RAG query failed, returning VLM output")
            return VLMAgentResponse(
                name=address,
                facility_description=vlm_caption,
                success=True,
                error_message=None,
            )
