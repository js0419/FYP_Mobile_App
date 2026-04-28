import json
import mimetypes
import os
from typing import Any, Optional

from dotenv import load_dotenv
from fastapi import FastAPI, File, Form, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from google import genai
from google.genai import types
from pydantic import BaseModel, Field
from supabase import create_client

load_dotenv()

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_SERVICE_ROLE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY")
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
GEMINI_MODEL = os.getenv("GEMINI_MODEL", "gemini-2.5-flash")

if not SUPABASE_URL or not SUPABASE_SERVICE_ROLE_KEY:
    raise ValueError("Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY in .env")

if not GEMINI_API_KEY:
    raise ValueError("Missing GEMINI_API_KEY in .env")

supabase = create_client(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)
gemini_client = genai.Client()

app = FastAPI(title="AI Outfit Recommendation API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)


class BodyAnalysis(BaseModel):
    body_shape: str = Field(
        description="Approximate body shape such as pear, rectangle, apple, hourglass, inverted_triangle, or unknown"
    )
    confidence: float = Field(description="Confidence score between 0 and 1")
    style_summary: str = Field(
        description="Short explanation of the detected body shape and what fashion cuts suit it"
    )
    recommended_focus: list[str] = Field(default_factory=list)
    avoid: list[str] = Field(default_factory=list)


class OutfitChoice(BaseModel):
    outfit_type: str = Field(description="Either top_bottom_set or dress_set")
    reason: str = Field(description="Short reason why this outfit suits the detected body shape and style")
    score: float = Field(description="Overall match score between 0 and 1")
    top_id: Optional[str] = None
    bottom_id: Optional[str] = None
    outerwear_id: Optional[str] = None
    dress_id: Optional[str] = None
    accessory_id: Optional[str] = None


class GeminiRecommendation(BaseModel):
    body_analysis: BodyAnalysis
    outfits: list[OutfitChoice] = Field(default_factory=list)


@app.get("/")
def root():
    return {"message": "AI Outfit Recommendation API is running"}


@app.get("/health")
def health():
    return {"status": "ok"}


def _normalize_gender(gender: Optional[str]) -> str:
    value = (gender or "unisex").strip().lower()
    if value not in {"men", "women", "unisex"}:
        return "unisex"
    return value


def _guess_mime_type(upload: UploadFile) -> str:
    if upload.content_type and upload.content_type.startswith("image/"):
        return upload.content_type

    guessed, _ = mimetypes.guess_type(upload.filename or "")
    if guessed and guessed.startswith("image/"):
        return guessed

    return "image/jpeg"


def _safe_float(value: Any) -> float:
    try:
        return float(value)
    except Exception:
        return 0.0


def _fetch_candidate_products(
    preferred_style: Optional[str],
    gender: Optional[str],
) -> list[dict[str, Any]]:
    result = supabase.table("v_product_catalogue").select("*").execute()
    rows = result.data or []

    preferred_style_lower = (preferred_style or "").strip().lower()
    gender_value = _normalize_gender(gender)

    filtered: list[dict[str, Any]] = []

    for row in rows:
        if str(row.get("product_status", "")).lower() != "active":
            continue

        product_gender = str(row.get("product_gender", "unisex")).lower()
        if gender_value in {"men", "women"} and product_gender not in {gender_value, "unisex"}:
            continue

        available_sizes = [str(x) for x in (row.get("available_sizes") or [])]
        if not available_sizes:
            continue

        style_tags = [str(x) for x in (row.get("style_tags") or [])]
        style_match = 0
        if preferred_style_lower and any(tag.lower() == preferred_style_lower for tag in style_tags):
            style_match = 1

        filtered.append(
            {
                "product_id": row.get("product_id"),
                "product_name": row.get("product_name"),
                "category_name": row.get("category_name"),
                "product_gender": row.get("product_gender"),
                "product_type": row.get("product_type"),
                "fit_type": row.get("fit_type"),
                "color": row.get("color"),
                "material": row.get("material"),
                "product_price": _safe_float(row.get("product_price")),
                "product_description": row.get("product_description"),
                "style_tags": style_tags,
                "available_sizes": available_sizes,
                "product_pic1": row.get("product_pic1"),
                "_style_match": style_match,
            }
        )

    filtered.sort(
        key=lambda x: (
            x["_style_match"],
            len(x["available_sizes"]),
            -x["product_price"],
        ),
        reverse=True,
    )

    category_limits = {
        "Top": 10,
        "Bottom": 10,
        "Outerwear": 6,
        "Dress": 8,
        "Accessories": 8,
    }

    selected: list[dict[str, Any]] = []
    used_ids: set[str] = set()

    for category, limit in category_limits.items():
        category_rows = [r for r in filtered if r.get("category_name") == category][:limit]
        for row in category_rows:
            product_id = str(row["product_id"])
            if product_id not in used_ids:
                selected.append(row)
                used_ids.add(product_id)

    for row in filtered:
        product_id = str(row["product_id"])
        if product_id not in used_ids:
            selected.append(row)
            used_ids.add(product_id)
        if len(selected) >= 40:
            break

    for row in selected:
        row.pop("_style_match", None)

    return selected[:40]


def _build_prompt(
    products: list[dict[str, Any]],
    preferred_style: Optional[str],
    gender: Optional[str],
) -> str:
    style_text = preferred_style.strip() if preferred_style else "any style"
    gender_text = _normalize_gender(gender)

    return f"""
You are a fashion stylist and body-shape analyst.

TASK 1
Analyze the uploaded body image and estimate the user's approximate body shape.
Use only broad fashion body-shape categories such as pear, rectangle, apple, hourglass, inverted_triangle, or unknown.

TASK 2
Using ONLY the product catalogue JSON below, create outfit recommendations that suit:
- the detected body shape
- the requested style: {style_text}
- the requested gender catalogue: {gender_text}

STRICT RULES
- Use ONLY product_id values that exist in the provided catalogue.
- Do NOT invent products.
- Recommend up to 5 outfit sets only.
- Prefer style tags that match "{style_text}" when possible.
- Use one of these outfit_type values only:
  - "top_bottom_set"
  - "dress_set"
- A top_bottom_set should include:
  - top_id
  - bottom_id
  - optional outerwear_id
  - optional accessory_id
- A dress_set should include:
  - dress_id
  - optional outerwear_id
  - optional accessory_id
- Keep the reason short, practical, and fashion-focused.
- Score must be between 0 and 1.
- Do not infer sensitive traits such as ethnicity, health condition, or age.
- Focus only on approximate body shape for outfit suitability.

PRODUCT CATALOGUE JSON
{json.dumps(products, ensure_ascii=False)}
""".strip()


def _call_gemini_for_recommendation(
    image_bytes: bytes,
    mime_type: str,
    preferred_style: Optional[str],
    gender: Optional[str],
    products: list[dict[str, Any]],
) -> GeminiRecommendation:
    prompt = _build_prompt(products, preferred_style, gender)

    response = gemini_client.models.generate_content(
        model=GEMINI_MODEL,
        contents=[
            types.Part.from_bytes(
                data=image_bytes,
                mime_type=mime_type,
            ),
            prompt,
        ],
        config={
            "response_mime_type": "application/json",
            "response_json_schema": GeminiRecommendation.model_json_schema(),
            "temperature": 0.2,
        },
    )

    if not response.text:
        raise HTTPException(status_code=500, detail="Gemini returned an empty response.")

    try:
        return GeminiRecommendation.model_validate_json(response.text)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to parse Gemini response: {e}")


def _build_item(
    product_lookup: dict[str, dict[str, Any]],
    product_id: Optional[str],
    score: float,
) -> Optional[dict[str, Any]]:
    if not product_id:
        return None

    product = product_lookup.get(product_id)
    if not product:
        return None

    available_sizes = product.get("available_sizes") or []
    size_display = " / ".join(str(x) for x in available_sizes[:4]) if available_sizes else "-"

    return {
        "product_id": product.get("product_id"),
        "product_name": product.get("product_name"),
        "product_price": product.get("product_price"),
        "recommended_size": size_display,
        "score": round(score, 4),
    }


def _transform_gemini_output(
    gemini_result: GeminiRecommendation,
    products: list[dict[str, Any]],
) -> dict[str, Any]:
    product_lookup = {
        str(product["product_id"]): product
        for product in products
        if product.get("product_id")
    }

    final_outfits: list[dict[str, Any]] = []

    for outfit in gemini_result.outfits:
        outfit_type = (outfit.outfit_type or "").strip().lower()

        if outfit_type == "top_bottom_set":
            if not outfit.top_id or not outfit.bottom_id:
                continue
        elif outfit_type == "dress_set":
            if not outfit.dress_id:
                continue
        else:
            continue

        outfit_items = {
            "top": _build_item(product_lookup, outfit.top_id, outfit.score),
            "bottom": _build_item(product_lookup, outfit.bottom_id, outfit.score),
            "outerwear": _build_item(product_lookup, outfit.outerwear_id, outfit.score),
            "dress": _build_item(product_lookup, outfit.dress_id, outfit.score),
            "accessory": _build_item(product_lookup, outfit.accessory_id, outfit.score),
        }

        final_outfits.append(
            {
                "outfit_type": outfit_type,
                "reason": outfit.reason,
                "score": round(float(outfit.score), 4),
                "outfit_items": outfit_items,
            }
        )

    return {
        "body_analysis": gemini_result.body_analysis.model_dump(),
        "count": len(final_outfits),
        "outfits": final_outfits,
    }


def _try_log_recommendation(
    user_id: Optional[str],
    preferred_style: Optional[str],
    payload: dict[str, Any],
) -> None:
    if not user_id:
        return

    style_id = None
    style_name = (preferred_style or "").strip()
    if style_name:
        try:
            style_result = (
                supabase.table("styles")
                .select("style_id")
                .ilike("style_name", style_name)
                .limit(1)
                .execute()
            )
            style_rows = style_result.data or []
            if style_rows:
                style_id = style_rows[0].get("style_id")
        except Exception:
            style_id = None

    try:
        supabase.table("ai_recommendations").insert(
            {
                "user_id": user_id,
                "requested_style_id": style_id,
                "recommended_products": payload,
            }
        ).execute()
    except Exception:
        # Logging failure should not break the recommendation flow.
        pass


@app.post("/recommend_outfits")
async def recommend_outfits(
    image: UploadFile = File(...),
    user_id: Optional[str] = Form(default=None),
    preferred_style: Optional[str] = Form(default=None),
    gender: Optional[str] = Form(default=None),
):
    try:
        if not image.filename:
            raise HTTPException(status_code=400, detail="Image file is required.")

        image_bytes = await image.read()
        if not image_bytes:
            raise HTTPException(status_code=400, detail="Uploaded image is empty.")

        mime_type = _guess_mime_type(image)
        if not mime_type.startswith("image/"):
            raise HTTPException(status_code=400, detail="Only image uploads are supported.")

        products = _fetch_candidate_products(preferred_style, gender)
        if not products:
            raise HTTPException(status_code=404, detail="No suitable products found in the catalogue.")

        gemini_result = _call_gemini_for_recommendation(
            image_bytes=image_bytes,
            mime_type=mime_type,
            preferred_style=preferred_style,
            gender=gender,
            products=products,
        )

        payload = _transform_gemini_output(gemini_result, products)
        _try_log_recommendation(user_id, preferred_style, payload)

        return payload

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to get outfit recommendations: {str(e)}",
        )