from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field
from supabase import create_client
from dotenv import load_dotenv
from fastapi.middleware.cors import CORSMiddleware
import os

load_dotenv()

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_SERVICE_ROLE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY")

if not SUPABASE_URL or not SUPABASE_SERVICE_ROLE_KEY:
    raise ValueError("Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY in .env")

supabase = create_client(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

app = FastAPI(title="AI Outfit Recommendation API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)


class RecommendRequest(BaseModel):
    user_id: str | None = None
    height: float | None = Field(default=None, gt=0)
    weight: float | None = Field(default=None, gt=0)
    preferred_style: str | None = None
    gender: str | None = None


@app.get("/")
def root():
    return {"message": "AI Outfit Recommendation API is running"}


@app.get("/health")
def health():
    return {"status": "ok"}


@app.post("/recommend_outfits")
def recommend_outfits(req: RecommendRequest):
    try:
        gender_value = req.gender.lower() if req.gender else None

        if gender_value not in (None, "men", "women", "unisex"):
            raise HTTPException(
                status_code=400,
                detail="gender must be one of: men, women, unisex"
            )

        rpc_payload = {
            "p_user_id": req.user_id,
            "p_height_cm": req.height,
            "p_weight_kg": req.weight,
            "p_style_name": req.preferred_style,
            "p_gender": gender_value,
        }

        result = supabase.rpc("recommend_outfit_set", rpc_payload).execute()
        rows = result.data or []

        return {
            "count": len(rows),
            "outfits": rows
        }

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to get outfit recommendations: {str(e)}"
        )