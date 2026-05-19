# Deploy NoorAI backend to Google Cloud Run

This guide deploys the FastAPI backend to **Google Cloud Run** using one of your
**trial billing accounts**. The app stays free for end users; you only spend
trial credit (and Cloud Run's generous always-free tier covers hackathon-level
traffic anyway — typically $0/month).

## Why Cloud Run over Render

| Render free | Cloud Run |
|---|---|
| Sleeps after 15 min → 30–50 s cold start (bad for live judging) | Scales to zero, but ~1–2 s warm-up |
| Custom domain costs money | Free custom domain mapping |
| No persistent disk | Not needed — JSON data ships inside the image |
| No region near Pakistan | `asia-south1` (Mumbai) — fastest for PK users |

## One-time setup (10 min)

### 1. Install the Google Cloud CLI

Windows: download from [cloud.google.com/sdk/docs/install](https://cloud.google.com/sdk/docs/install).
After install, open a new PowerShell window and run:

```powershell
gcloud --version
gcloud auth login
```

### 2. Pick a project + billing account

List what you have:

```powershell
gcloud projects list
gcloud billing accounts list
```

Either pick an existing project or create a fresh one for NoorAI:

```powershell
gcloud projects create noorai-hackathon --name="NoorAI"
gcloud config set project noorai-hackathon
```

Link it to whichever trial billing account has the **most remaining credit**.
Copy the `ACCOUNT_ID` from the `gcloud billing accounts list` output, then:

```powershell
gcloud billing projects link noorai-hackathon --billing-account=ACCOUNT_ID
```

### 3. Enable the APIs Cloud Run needs

```powershell
gcloud services enable run.googleapis.com `
                       artifactregistry.googleapis.com `
                       cloudbuild.googleapis.com
```

## Deploy (every time you ship)

From the repo root:

```powershell
gcloud run deploy noorai-backend `
  --source backend `
  --region asia-south1 `
  --platform managed `
  --allow-unauthenticated `
  --memory 512Mi `
  --cpu 1 `
  --min-instances 0 `
  --max-instances 3 `
  --set-env-vars GEMINI_API_KEY=PASTE_YOUR_KEY_HERE
```

What happens:
1. Cloud Build packages `backend/` using the `Dockerfile`.
2. Pushes the image to Artifact Registry.
3. Cloud Run starts a service and gives you a public HTTPS URL like
   `https://noorai-backend-xxxxxx-as.a.run.app`.

> Why `--allow-unauthenticated`? So the Flutter app can call it without a
> service-account token. The endpoints themselves still require user login
> via the Bearer token from `/api/auth/login`.

### Wire the URL into the Flutter app

Edit [mobile/lib/services/api_service.dart](../mobile/lib/services/api_service.dart):

```dart
static const String baseUrl = 'https://noorai-backend-xxxxxx-as.a.run.app/api';
```

Rebuild the APK:

```powershell
cd mobile
flutter build apk --release
```

## Cost reality check

Cloud Run always-free tier per month:
- 2 million requests
- 360,000 GB-seconds of memory
- 180,000 vCPU-seconds

A hackathon demo with a few hundred requests will not even register on the meter.
After the trial credit expires, you'd need ~50,000 sessions/month before you owe
anything. The app being free for end users doesn't change this — Cloud Run bills
**you**, not them.

## Heads-up about the JSON storage

`bookings.json`, `users.json`, `messages.json`, and the `voice_notes/` folder
live **inside the container image**. Anything written at runtime survives only
until Cloud Run replaces the instance (i.e. fine for a demo, NOT durable).

For real production, swap the file-backed stores in `backend/utils/users.py`,
`backend/utils/chat.py`, and `backend/agents/booking_agent.py` for Firestore
or Cloud SQL. The interfaces are small enough to migrate in an afternoon.

## Common gotchas

| Symptom | Fix |
|---|---|
| `Cloud Build has not been used in project …` | Re-run the `gcloud services enable` step. |
| Build succeeds but service returns 500 | Check logs: `gcloud run services logs read noorai-backend --region asia-south1 --limit 50` |
| Mobile app still hits localhost | You forgot to update `baseUrl` in `api_service.dart` and rebuild. |
| Voice notes 404 on playback | `voice_notes/` was excluded by `.dockerignore`. That's intentional — new ones uploaded post-deploy work; old local ones don't ship to prod. |
