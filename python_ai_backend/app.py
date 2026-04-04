from fastapi import FastAPI
from pydantic import BaseModel
from supabase import create_client
from dotenv import load_dotenv
import os

load_dotenv()

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_SERVICE_ROLE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY")

if not SUPABASE_URL or not SUPABASE_SERVICE_ROLE_KEY:
    raise ValueError("Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY in .env")

supabase = create_client(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

app = FastAPI(title="AI Recommendation API")


class RecommendRequest(BaseModel):
    user_id: str | None = None
    height: float
    weight: float
    preferred_style: str
    gender: str | None = None
    limit: int = 10


def estimate_size(height_cm: float, weight_kg: float) -> str:
    bmi = weight_kg / ((height_cm / 100) ** 2)

    if bmi < 18.5:
        return "S"
    elif bmi < 24.9:
        return "M"
    elif bmi < 29.9:
        return "L"
    return "XL"


def normalize(value: float, max_value: float) -> float:
    if max_value <= 0:
        return 0.0
    return value / max_value


def fetch_catalog():
    products_res = (
        supabase.table("products")
        .select("*")
        .eq("product_status", "active")
        .execute()
    )
    products = products_res.data or []

    quantities_res = (
        supabase.table("quantities")
        .select("quantity_id, product_id, size, product_stock, product_sold")
        .execute()
    )
    quantities = quantities_res.data or []

    qty_map = {}
    for q in quantities:
        pid = q["product_id"]
        qty_map.setdefault(pid, []).append(q)

    catalog = []
    for p in products:
        pid = p["product_id"]
        variants = qty_map.get(pid, [])

        available_sizes = [
            str(v["size"]).upper()
            for v in variants
            if (v.get("product_stock") or 0) > 0
        ]

        total_stock = sum((v.get("product_stock") or 0) for v in variants)
        total_sold = sum((v.get("product_sold") or 0) for v in variants)

        if total_stock <= 0:
            continue

        catalog.append({
            **p,
            "available_sizes": available_sizes,
            "total_stock": total_stock,
            "total_sold": total_sold,
        })

    return catalog


@app.get("/")
def root():
    return {"message": "AI Recommendation API is running"}


@app.post("/recommend")
def recommend(req: RecommendRequest):
    catalog = fetch_catalog()
    recommended_size = estimate_size(req.height, req.weight)
    max_sold = max([p.get("total_sold", 0) for p in catalog], default=0)

    scored = []

    for product in catalog:
        style_text = " ".join([
            str(product.get("style_tag", "")),
            str(product.get("product_type", "")),
            str(product.get("fit_type", "")),
            str(product.get("material", "")),
            str(product.get("color", "")),
            str(product.get("product_description", "")),
        ]).lower()

        style_match = 1.0 if req.preferred_style.lower() in style_text else 0.0
        size_fit = 1.0 if recommended_size in product["available_sizes"] else 0.0
        popularity = normalize(product.get("total_sold", 0), max_sold)

        if req.gender:
            product_gender = str(product.get("product_gender", "")).upper()
            if product_gender not in ["", "UNISEX", req.gender.upper()]:
                continue

        compatibility_score = (
            0.5 * style_match +
            0.3 * size_fit +
            0.2 * popularity
        )

        if style_match <= 0:
            continue

        scored.append({
            **product,
            "recommended_size": recommended_size,
            "style_match": style_match,
            "size_fit": size_fit,
            "popularity": popularity,
            "final_score": compatibility_score,
        })

    scored.sort(key=lambda x: x["final_score"], reverse=True)
    result = scored[:req.limit]

    if req.user_id:
        try:
            supabase.table("ai_recommendation").insert({
                "user_id": req.user_id,
                "height": req.height,
                "weight": req.weight,
                "preferred_style": req.preferred_style,
                "recommended_products": [
                    {
                        "product_id": item["product_id"],
                        "score": item["final_score"]
                    }
                    for item in result
                ]
            }).execute()
        except Exception as e:
            print("Failed to save ai_recommendation log:", e)

    return {
        "recommended_size": recommended_size,
        "count": len(result),
        "items": result
    }