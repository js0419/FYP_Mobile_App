# FYP_Mobile_App

A Flutter mobile app with a Python backend for AI-based outfit recommendations.

## Overview

This project combines:

- a Flutter mobile app
- a FastAPI backend
- Supabase for data storage
- Gemini AI for image-based outfit recommendations

The app allows a user to upload an image, and the backend analyzes it to suggest suitable outfits from the product catalogue.

## Features

Based on the current implementation, this project includes:

- Flutter app with Supabase initialization
- AI outfit recommendation API
- Image upload handling
- Product filtering from Supabase
- Outfit generation using Gemini
- Recommendation logging to Supabase
- Custom app UI components such as:
  - app bar
  - drawer
  - footer

## Tech Stack

### Frontend
- Flutter
- Dart
- Supabase Flutter
- `intl`
- `image_picker`
- `flutter_secure_storage`
- `flutter_paypal_payment`
- `http`
- `file_picker`

### Backend
- FastAPI
- Uvicorn
- Supabase Python client
- Google GenAI
- Pydantic
- python-dotenv
- python-multipart

## Project Structure

- `lib/` – Flutter app source code
- `lib/screens/` – app screens
- `lib/services/` – business logic and API services
- `lib/widgets/` – reusable UI components
- `python_ai_backend/` – FastAPI backend service
- `android/`, `ios/`, `web/`, `windows/`, `macos/`, `linux/` – Flutter platform support files

## Backend API

The backend provides these routes:

### `GET /`
Returns a simple message showing the API is running.

### `GET /health`
Returns backend health status.

### `POST /recommend_outfits`
Accepts:
- `image` – uploaded image file
- `user_id` – optional
- `preferred_style` – optional
- `gender` – optional

Returns:
- body analysis
- outfit recommendations
- matching product information
- total number of outfits

## How It Works

1. User uploads an image.
2. Gemini analyzes the image to estimate body shape.
3. The backend loads suitable products from Supabase.
4. Gemini generates outfit recommendations using only products from the catalogue.
5. The backend returns structured recommendation results.

## Configuration

### Flutter App
The app initializes Supabase in `lib/main.dart` using:
- Supabase URL
- Supabase anon key

### Backend
The backend expects these environment variables in `python_ai_backend/.env`:

- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`
- `GEMINI_API_KEY`
- `GEMINI_MODEL` (optional)

## Run the Backend

From the `python_ai_backend/` folder:

```bash
pip install -r requirements.txt
python -m uvicorn app:app --host 127.0.0.1 --port 8000 --reload
```

## Notes

- The Flutter project name in `pubspec.yaml` is `fyp_p2`.
- This README only reflects what is already implemented in the repository.
- No extra features have been assumed.


admin: admin@gmail.com
pass: Js2004@

customer: siajinsheng@gmail.com
pass: qwer12@


Paypal Payment account:
paypalsandboxpayment@gmail.com
qwer1234@

Paypal Payment visa card:
Card Number: 4293121245636222
Expiry: 05/2031
CVC code: Any 3 digits

API Key:
re_D7Cpi2ca_MyYXBH9Ckryqi61RYxfLsggE

FROM EMAIL:
onboarding@resend.dev