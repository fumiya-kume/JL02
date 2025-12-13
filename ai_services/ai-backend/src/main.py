from fastapi import FastAPI
import base64
import io
import os
from typing import Optional
from PIL import Image
from pydantic import BaseModel
import uvicorn
from fastapi import FastAPI, File, Form, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from PIL import Image
from pydantic import BaseModel
import httpx

app = FastAPI()


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
    address: str = File(..., description="Adress of the location"),
    latitude: float = File(...),
    longitude: float = File(...),
    text: Optional[str] = Form(None, description="Text prompt for the image"),
    temperature: Optional[float] = Form(0.7, description="Temperature for generation"),
    top_p: Optional[float] = Form(0.99, description="Top-p value for generation"),
    max_new_tokens: Optional[int] = Form(
        128, description="Maximum number of new tokens"
    ),
    repetition_penalty: Optional[float] = Form(1.05, description="Repetition penalty"),
):
    ngrok_domain = os.getenv("NGROK_DOMAIN")
    if not ngrok_domain:
        raise HTTPException(
            status_code=500, detail="NGROK_DOMAIN environment variable not set"
        )

    image_data = await image.read()

    # もしtextが文字列型ではない場合は、補完する
    if not isinstance(text, str):
        text = "画像中のランドマークについて、3行程度で具体的に説明してください。"

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
