# NoorAI — Submission Guide
## What You Need From Your Side + How to Deploy

---

## 1. The ONE Thing You Must Get: Gemini API Key

> **Good news: You do NOT need Google Cloud billing for this.**

Get your key from **Google AI Studio** — it's a separate product with a **free tier**:

1. Go to: https://aistudio.google.com/app/apikey
2. Sign in with your Google account
3. Click **"Create API Key"**
4. Copy the key (looks like: `AIzaSy...`)
5. Paste it into `backend/.env`:
   ```
   GEMINI_API_KEY=AIzaSy_your_actual_key_here
   NOORAI_OFFLINE_MODE=0
   ```

**Free tier limits (more than enough for demo + judges):**
- 15 requests/minute, 1 million tokens/day on Gemini 2.0 Flash
- No credit card required

**If you want to skip Gemini entirely** (demo runs with regex-only NLP):
```
NOORAI_OFFLINE_MODE=1
```

---

## 2. Your Google Cloud Trial — What To Use It For

Your trial credits are great for **Cloud Run deployment** (optional, only needed if you want a public URL instead of running locally). You do NOT need GCP for the hackathon demo itself.

---

## 3. Software You Need Installed

| Tool | Version | Download |
|------|---------|----------|
| Python | 3.11+ | https://python.org |
| Flutter SDK | 3.x+ | https://flutter.dev/docs/get-started/install |
| Android Studio | Any | https://developer.android.com/studio |
| Git | Any | Already installed |

Verify with:
```bash
python --version      # Should show 3.11+
flutter --version     # Should show 3.x
flutter doctor        # Fix any issues shown
```

---

## 4. Running Locally (For Demo Day)

### Step 1 — Set up backend
```bash
cd backend
pip install -r requirements.txt

# Edit .env:
# GEMINI_API_KEY=your_key_here
# NOORAI_OFFLINE_MODE=0

uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

Visit http://localhost:8000 → should show:
```json
{"name": "NoorAI Backend", "status": "ok", "offline_mode": false}
```

Test the API:
```bash
curl -X POST http://localhost:8000/api/find-therapists \
  -H "Content-Type: application/json" \
  -d '{"user_message": "5 saal ke bete ko speech therapist Gulberg Lahore"}'
```

### Step 2 — Run Flutter app

**On Android Emulator:**
```bash
cd mobile
flutter pub get
flutter run
```

**On Physical Android Device:**
1. Enable USB Debugging: Settings → Developer Options → USB Debugging ON
2. Connect phone via USB
3. Run `flutter run`
4. The app will ask permission to install — approve it

**Emulator vs real device baseUrl:**
- Emulator: `http://10.0.2.2:8000/api` ← already set in `api_service.dart`
- Real device: Change to your PC's local IP, e.g. `http://192.168.1.x:8000/api`

Find your PC's IP:
```bash
# Windows
ipconfig | findstr IPv4

# Then update mobile/lib/services/api_service.dart line 9:
static const String baseUrl = 'http://192.168.1.YOUR_IP:8000/api';
```

---

## 5. Building the APK (Hackathon Submission)

```bash
cd mobile
flutter pub get
flutter build apk --release
```

APK location: `mobile/build/app/outputs/flutter-apk/app-release.apk`

**Install on device:**
```bash
flutter install
# or drag-drop the APK onto your phone
```

---

## 6. App Icon — How to Generate

The logo SVG is at `mobile/assets/noorai_logo.svg`.

**To generate proper app icons:**

1. Convert the SVG to a 1024×1024 PNG using any of these:
   - https://svgtopng.com (free, online)
   - Inkscape (free desktop app)
   - Figma (free online)

2. Save the PNG as `mobile/assets/app_icon.png`

3. Run:
   ```bash
   cd mobile
   flutter pub get
   flutter pub run flutter_launcher_icons
   ```

This generates icons for all Android/iOS sizes automatically.

---

## 7. Deploying on Render (Backend — Free Tier)

> Use this if you want a public URL instead of running locally.

1. Push your code to GitHub (if not already):
   ```bash
   git add .
   git commit -m "NoorAI complete"
   git push
   ```

2. Go to **https://render.com** → Sign up free

3. Click **New → Web Service** → Connect GitHub repo

4. Configure:
   | Field | Value |
   |-------|-------|
   | Root Directory | `backend` |
   | Environment | Python 3 |
   | Build Command | `pip install -r requirements.txt` |
   | Start Command | `uvicorn main:app --host 0.0.0.0 --port $PORT` |

5. Add Environment Variable:
   - Key: `GEMINI_API_KEY`
   - Value: your API key

6. Click **Create Web Service** — deploys in ~2 minutes

7. Update Flutter app's base URL:
   ```dart
   // mobile/lib/services/api_service.dart, line 9
   static const String baseUrl = 'https://your-service.onrender.com/api';
   ```

   Then rebuild APK:
   ```bash
   cd mobile
   flutter build apk --release
   ```

---

## 8. Deploying on Heroku (Alternative)

```bash
# 1. Install Heroku CLI from https://devcenter.heroku.com/articles/heroku-cli

# 2. Create Procfile in backend/ folder:
echo "web: uvicorn main:app --host 0.0.0.0 --port \$PORT" > backend/Procfile

# 3. Deploy
cd backend
heroku login
heroku create noorai-backend-demo
heroku config:set GEMINI_API_KEY=your_key_here
git push heroku main
```

---

## 9. Deploying on Google Cloud Run (Uses Your Trial Credits)

```bash
cd backend

# Authenticate
gcloud auth login
gcloud config set project YOUR_PROJECT_ID

# Deploy (builds automatically from source)
gcloud run deploy noorai-backend \
  --source . \
  --platform managed \
  --region asia-south1 \
  --allow-unauthenticated \
  --set-env-vars GEMINI_API_KEY=your_key_here \
  --memory 512Mi
```

Cost estimate: ~$0 with trial credits for demo volume.

---

## 10. Hackathon Submission Checklist

### Code & APK
- [ ] `backend/.env` has real `GEMINI_API_KEY`
- [ ] Backend starts without errors (`uvicorn main:app --reload`)
- [ ] Flutter app connects to backend (`flutter run` works)
- [ ] APK built: `flutter build apk --release`
- [ ] APK installs and runs on a physical device

### Demo Screens (Test These)
- [ ] Screen 1 (Home): Type Roman Urdu query, tap Find
- [ ] Screen 2 (Results): Shows 3 ranked therapists with real intent chips
- [ ] Screen 3 (Detail): Schedule tab shows slots, tap one, Book Now works
- [ ] Screen 4 (Booking): Shows real confirmation code, sessions, WhatsApp mock
- [ ] Screen 5 (Follow-up): Shows 5 scheduled events
- [ ] Screen 6 (Agent Trace): Shows all 7 agents with handoff arrows
- [ ] Screen 7 (Dispute): Tap "Therapist Cancelled" → shows Dr. Sara alternative
- [ ] Screen 8 (Baseline): Shows AI vs Traditional side-by-side

### Stress Test (Demo this live)
- [ ] Make a booking
- [ ] Call `POST http://localhost:8000/api/admin/cancel-therapist/{booking_id}`
- [ ] Show Dispute screen → Agent auto-proposes alternative

### Documentation
- [ ] Screenshot Antigravity Workplan → add to `docs/ANTIGRAVITY_WALKTHROUGH.md`
- [ ] Screenshot Agent Trace (Screen 6) → add to README
- [ ] Architecture diagram in README
- [ ] Demo video recorded (3–5 min, follow `docs/DEMO_SCRIPT.md`)

---

## 11. Common Problems & Fixes

| Problem | Fix |
|---------|-----|
| `ModuleNotFoundError` on backend start | Run `pip install -r requirements.txt` first |
| App shows mock data only | Backend not running or wrong IP in `api_service.dart` |
| `flutter pub get` fails | Run `flutter doctor` and fix SDK issues |
| Gemini API errors | Set `NOORAI_OFFLINE_MODE=1` for regex fallback |
| APK won't install | Enable "Install from unknown sources" in phone settings |
| `10.0.2.2` not working on real device | Use your PC's local IP (run `ipconfig` on Windows) |
| VS Code shows red errors in Dart files | Open VS Code with `mobile/` as the workspace root, not `noorai/` |

---

## 12. The VS Code "Red Errors" Explained

If VS Code shows errors like `Target of URI doesn't exist: 'package:flutter/material.dart'` — **these are fake**.  
The Dart analyzer needs the **Flutter project root** as the workspace, not the repo root.

**Fix:**
```
File → Open Folder → select the "mobile" folder (not "noorai")
```

OR add this to `noorai/.vscode/settings.json`:
```json
{
  "dart.projectSearchDepth": 5
}
```

Then run `flutter pub get` from the `mobile/` directory.

---

*Built for Google Antigravity Hackathon — Challenge 2. Submission deadline: May 20, 2026.*
