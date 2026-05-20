Update Todos

Add Flutter deps (audio + storage + intl)

Backend: user profile + auth endpoints (JSON store)

Backend: chat + voice note endpoints with static file serving

Backend: bookings-by-user list endpoint

Mobile: User/Message models + extend ApiService

Mobile: Splash + Onboarding (parent profile setup)

Mobile: Auth screen (login/signup)

Mobile: Main shell with bottom nav (Home/Bookings/Chats/Profile)

Mobile: Bookings history screen

Mobile: Therapist chat screen with voice note record/play

Mobile: Profile screen

Mobile: Rewire main.dart + add chat entry from therapist detail

Add Android mic permission to manifest

Deploy: Dockerfile + GCP Cloud Run guide
All done. Here's what changed and what you do next.

What I built
Backend (backend/main.py, backend/utils/users.py, backend/utils/chat.py)

/api/auth/register, /api/auth/login, /api/auth/me (PATCH for profile updates) — token-based, password hashed with per-user salt
/api/bookings — list current user's bookings
/api/chats, /api/chats/{id} (GET + POST text), /api/chats/{id}/voice (multipart upload), /api/voice-notes/{file} (audio serve)
Added python-multipart + email-validator to backend/requirements.txt
Mobile (mobile/lib/)

New screens: splash_screen.dart, auth_screen.dart, onboarding_screen.dart, main_shell.dart (bottom nav), bookings_history_screen.dart, chats_list_screen.dart, therapist_chat_screen.dart (WhatsApp-style voice notes with record + waveform + playback), profile_screen.dart (view + edit)
Models: user_profile.dart, chat_message.dart
Services: auth_service.dart (SharedPreferences-backed session) + extended api_service.dart
Unified theme in theme.dart — consistent palette, button styles, input fields
Auth-gated routing in main.dart — Splash decides Auth → Onboarding → MainShell
"Message" button added to provider_detail_screen.dart
Android permissions added in AndroidManifest.xml
Deploy (backend/Dockerfile, docs/GCP_DEPLOY.md)

Full Cloud Run guide with the exact gcloud run deploy command
What you do next

# 1. Install new deps
cd mobile
flutter pub get

cd ..\backend
pip install -r requirements.txt

# 2. Run it
cd ..\backend
uvicorn main:app --reload
# new terminal
cd mobile
flutter run
Flow you'll see: Splash → Auth (sign up with any email/password) → Onboarding (3 steps) → Main app with bottom tabs. The mic button appears in the chat composer when the text field is empty.

API keys recap
You still only need one key to ship: the Gemini key from aistudio.google.com/app/apikey into backend/.env. Voice notes work without Speech-to-Text because they're audio files, not transcribed.

Deploying to GCP
Cloud Run is the better choice over Render (1–2 s warm vs Render's 30–50 s cold start, free Mumbai region, your trial credit covers it, always-free tier covers the rest). Step-by-step in docs/GCP_DEPLOY.md. The app being free for users doesn't affect GCP billing — Cloud Run bills you, not them, and traffic at hackathon scale costs $0/month.

One real-prod caveat I called out in the deploy guide: the JSON file stores (users.json, messages.json, voice_notes/) live inside the container image and reset when Cloud Run replaces the instance. Fine for the demo; for production you'd swap them for Firestore. ~Afternoon of work, interfaces are small.