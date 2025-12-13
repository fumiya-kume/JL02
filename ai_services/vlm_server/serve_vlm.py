import base64
import io
import os
from typing import Optional

import torch
import uvicorn
from fastapi import FastAPI, File, Form, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from PIL import Image
from pydantic import BaseModel
from pyngrok import ngrok
from transformers import AutoModelForCausalLM, AutoProcessor, set_seed

# Configuration
MODEL_PATH = os.getenv("MODEL_PATH", "sbintuitions/sarashina2.2-vision-3b")
PORT = int(os.getenv("PORT", "8000"))
NGROK_AUTH_TOKEN = os.getenv("NGROK_AUTH_TOKEN", None)
# Ngrok Domain Configuration:
# To use a fixed domain, first reserve a static domain in your ngrok Dashboard:
# 1. Go to ngrok Dashboard -> Domains -> Create Domain
# 2. Set NGROK_DOMAIN environment variable (e.g., "your-domain.ngrok.app")
# 3. Ensure NGROK_AUTH_TOKEN is set for authenticated access
NGROK_DOMAIN = os.getenv("NGROK_DOMAIN", None)  # Fixed domain for ngrok (e.g., "your-domain.ngrok.app")
NGROK_HTTPS_ONLY = os.getenv("NGROK_HTTPS_ONLY", "false").lower() == "true"  # HTTPS only tunnel

# Global variables for model and processor
model = None
processor = None

class VLMRequest(BaseModel):
    text: str
    temperature: Optional[float] = 0.7
    top_p: Optional[float] = 0.95
    max_new_tokens: Optional[int] = 512
    repetition_penalty: Optional[float] = 1.2

class VLMResponse(BaseModel):
    generated_text: str
    success: bool
    error_message: Optional[str] = None

# FastAPI app
app = FastAPI(
    title="Vision Language Model Inference Server",
    description="API server for Vision Language Model inference with image and text input",
    version="1.0.0"
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

def load_model():
    """Load the VLM model and processor"""
    global model, processor

    print(f"Loading model from: {MODEL_PATH}")

    try:
        # Load processor
        processor = AutoProcessor.from_pretrained(MODEL_PATH, trust_remote_code=True)

        # Load model
        model = AutoModelForCausalLM.from_pretrained(
            MODEL_PATH,
            device_map="cuda" if torch.cuda.is_available() else "cpu",
            torch_dtype=torch.bfloat16 if torch.cuda.is_available() else torch.float32,
            trust_remote_code=True,
        )

        print("Model loaded successfully!")

    except Exception as e:
        print(f"Error loading model: {str(e)}")
        raise e

def process_image_binary(image_data: bytes) -> Image.Image:
    """Process binary image data and return PIL Image"""
    try:
        image = Image.open(io.BytesIO(image_data)).convert("RGB")
        return image
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Invalid image data: {str(e)}")

def resize_image_to_target_pixels(image: Image.Image, target_pixels: int = 262144) -> Image.Image:
    """
    Resize image to approximately target number of pixels while maintaining aspect ratio.

    Args:
        image: PIL Image object to resize
        target_pixels: Target number of pixels (default: 240,000)

    Returns:
        Resized PIL Image object
    """
    # Get current dimensions
    width, height = image.size
    current_pixels = width * height

    # If already close to target, return as is
    if abs(current_pixels - target_pixels) / target_pixels < 0.05:  # Within 5%
        print(f"📐 Image already optimal: {width}x{height} ({current_pixels} pixels)")
        return image

    # Calculate scale factor to reach target pixels
    scale_factor = (target_pixels / current_pixels) ** 0.5

    # Calculate new dimensions
    new_width = int(width * scale_factor)
    new_height = int(height * scale_factor)

    # Ensure minimum dimensions
    new_width = max(new_width, 32)
    new_height = max(new_height, 32)

    # Resize image using high-quality resampling
    resized_image = image.resize((new_width, new_height), Image.Resampling.LANCZOS)

    final_pixels = new_width * new_height
    print(f"📐 Image resized: {width}x{height} ({current_pixels} pixels) → {new_width}x{new_height} ({final_pixels} pixels)")

    return resized_image

def generate_vlm_response(image: Image.Image, text: str, temperature: float,
                         top_p: float, max_new_tokens: int, repetition_penalty: float) -> str:
    """Generate response from VLM model"""
    global model, processor

    if model is None or processor is None:
        raise HTTPException(status_code=500, detail="Model not loaded")

    try:
        # Set random seed for reproducibility
        set_seed(42)

        # Prepare message format for chat template
        message = [
            {
                "role": "user",
                "content": [
                    {
                        "type": "image",
                        "image": image,  # PIL Image object
                    },
                    {
                        "type": "text",
                        "text": text,
                    },
                ],
            }
        ]

        # Apply chat template
        text_prompt = processor.apply_chat_template(message, add_generation_prompt=True)

        # Process inputs
        inputs = processor(
            text=[text_prompt],
            images=[image],
            padding=True,
            return_tensors="pt",
        )

        # Move to device
        inputs = inputs.to(model.device)

        # Generate response
        print("Starting generation...")
        with torch.no_grad():
            output_ids = model.generate(
                **inputs,
                max_new_tokens=max_new_tokens,
                temperature=temperature,
                top_p=top_p,
                repetition_penalty=repetition_penalty,
                do_sample=True,
            )

        # Decode generated text
        generated_ids = [
            output_ids[len(input_ids):] for input_ids, output_ids in zip(inputs.input_ids, output_ids)
        ]

        output_text = processor.batch_decode(
            generated_ids, skip_special_tokens=True, clean_up_tokenization_spaces=True
        )

        return output_text[0]

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Generation failed: {str(e)}")

@app.on_event("startup")
async def startup_event():
    """Load model on startup"""
    load_model()

@app.get("/")
async def root():
    """Root endpoint"""
    return {"message": "Vision Language Model Inference Server", "status": "running"}

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "model_loaded": model is not None and processor is not None,
        "device": str(model.device) if model else "unknown"
    }

@app.post("/inference", response_model=VLMResponse)
async def vlm_inference(
    image: UploadFile = File(..., description="Image file (PNG, JPG, etc.)"),
    text: str = Form(..., description="Text prompt for the image"),
    temperature: Optional[float] = Form(0.7, description="Temperature for generation"),
    top_p: Optional[float] = Form(0.95, description="Top-p value for generation"),
    max_new_tokens: Optional[int] = Form(512, description="Maximum number of new tokens"),
    repetition_penalty: Optional[float] = Form(1.2, description="Repetition penalty")
):
    """
    VLM inference endpoint

    The image will be automatically resized to approximately 240,000 pixels (maintaining aspect ratio)
    for optimal VLM processing performance and memory usage.

    - **image**: Image file (binary data - PNG, JPG, etc.)
    - **text**: Text prompt to describe what you want to know about the image
    - **temperature**: Controls randomness (0.1-2.0, default: 0.7)
    - **top_p**: Nucleus sampling parameter (0.1-1.0, default: 0.95)
    - **max_new_tokens**: Maximum tokens to generate (1-2048, default: 512)
    - **repetition_penalty**: Penalty for repetition (1.0-2.0, default: 1.2)
    """

    try:
        # Validate parameters
        if not 0.1 <= temperature <= 2.0:
            raise HTTPException(status_code=400, detail="Temperature must be between 0.1 and 2.0")
        if not 0.1 <= top_p <= 1.0:
            raise HTTPException(status_code=400, detail="top_p must be between 0.1 and 1.0")
        if not 1 <= max_new_tokens <= 2048:
            raise HTTPException(status_code=400, detail="max_new_tokens must be between 1 and 2048")
        if not 1.0 <= repetition_penalty <= 2.0:
            raise HTTPException(status_code=400, detail="repetition_penalty must be between 1.0 and 2.0")

        # Read and process image
        image_data = await image.read()
        processed_image = process_image_binary(image_data)

        # Resize image to optimal size for VLM processing
        resized_image = resize_image_to_target_pixels(processed_image)

        # Generate response
        generated_text = generate_vlm_response(
            resized_image, text, temperature, top_p, max_new_tokens, repetition_penalty
        )

        return VLMResponse(
            generated_text=generated_text,
            success=True
        )

    except HTTPException:
        raise
    except Exception as e:
        return VLMResponse(
            generated_text="",
            success=False,
            error_message=str(e)
        )

def setup_ngrok():
    """Setup ngrok tunnel with optional fixed domain and HTTPS-only configuration"""
    if NGROK_AUTH_TOKEN:
        ngrok.set_auth_token(NGROK_AUTH_TOKEN)
        print("🔑 Ngrok authentication token configured")
    else:
        print("⚠️ NGROK_AUTH_TOKEN not set - using ngrok without authentication")

    # Prepare tunnel configuration
    tunnel_options = {
        "addr": PORT,
        "proto": "http"
    }

    # Configure fixed domain if provided
    if NGROK_DOMAIN:
        tunnel_options["domain"] = NGROK_DOMAIN
        print(f"🔗 Using fixed domain: {NGROK_DOMAIN}")
    else:
        print("🎲 Using random ngrok domain (set NGROK_DOMAIN for fixed domain)")

    # Configure HTTPS-only if requested
    if NGROK_HTTPS_ONLY:
        tunnel_options["schemes"] = ["https"]
        print("🔒 HTTPS-only tunnel configured")

    # Create tunnel
    public_url = ngrok.connect(**tunnel_options)
    print(f"🌐 Public URL: {public_url}")
    print(f"📋 API Documentation: {public_url}/docs")
    print(f"❤️ Health Check: {public_url}/health")
    print(f"🔗 Inference endpoint: {public_url}/inference")

    return public_url

def main():
    """Main function to run the server"""
    print("🚀 Starting Vision Language Model Inference Server...")
    print(f"📦 Running with uv package manager")

    # Print configuration info
    if NGROK_DOMAIN:
        print(f"🏷️ Configured with fixed ngrok domain: {NGROK_DOMAIN}")
    if NGROK_HTTPS_ONLY:
        print("🔒 Configured for HTTPS-only access")

    # Setup ngrok tunnel
    try:
        public_url = setup_ngrok()
        print(f"✅ Ngrok tunnel established: {public_url}")
        if NGROK_DOMAIN:
            print("💡 Tip: Your fixed domain is now active and will remain consistent across restarts")
    except Exception as e:
        print(f"⚠️ Could not setup ngrok: {e}")
        print("🔧 Server will run locally only")
        if not NGROK_AUTH_TOKEN:
            print("💡 Tip: Set NGROK_AUTH_TOKEN environment variable to enable public access")
        if not NGROK_DOMAIN:
            print("💡 Tip: Set NGROK_DOMAIN environment variable to use a fixed URL")
        print(f"📋 Local API Documentation: http://localhost:{PORT}/docs")
        print(f"❤️ Local Health Check: http://localhost:{PORT}/health")
        print(f"🔗 Local Inference endpoint: http://localhost:{PORT}/inference")

    # Run the server
    print(f"🏃 Starting server on port {PORT}...")
    print("📝 Usage: Send POST requests to /inference with image file and text prompt")
    uvicorn.run(
        app,
        host="0.0.0.0",
        port=PORT,
        log_level="info"
    )

if __name__ == "__main__":
    main()