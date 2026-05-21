# NoorAI — Deployment Runbook

Backend: **FastAPI on Google Cloud Run**. Persistence: **Firestore** (auto-selected
when running on Cloud Run). Mobile: **Flutter** Android APK.

Run these from a machine with the **Google Cloud CLI** (`gcloud`) installed and
authenticated to the NoorAI project. The deployed backend URL the app already
points at is `https://noorai-backend-485583022901.asia-south1.run.app`.

---

## 1. One-time Google Cloud setup

```bash
# Authenticate and select the project.
gcloud auth login
gcloud config set project <YOUR_PROJECT_ID>

# Enable the APIs the backend uses.
gcloud services enable \
  run.googleapis.com \
  firestore.googleapis.com \
  storage.googleapis.com \
  artifactregistry.googleapis.com \
  cloudbuild.googleapis.com

# Create the Firestore database in Native mode (one per project).
# Use the same region as Cloud Run (asia-south1) for low latency.
gcloud firestore databases create --location=asia-south1

# (Voice notes) create a bucket for uploaded audio.
gcloud storage buckets create gs://noorai-voice-notes --location=asia-south1
```

The Cloud Run **runtime service account** needs Firestore + Storage access. The
default compute service account usually has Editor, which is enough; to scope it
explicitly:

```bash
PROJECT_NUMBER=$(gcloud projects describe <YOUR_PROJECT_ID> --format='value(projectNumber)')
SA="${PROJECT_NUMBER}-compute@developer.gserviceaccount.com"
gcloud projects add-iam-policy-binding <YOUR_PROJECT_ID> \
  --member="serviceAccount:${SA}" --role="roles/datastore.user"
gcloud projects add-iam-policy-binding <YOUR_PROJECT_ID> \
  --member="serviceAccount:${SA}" --role="roles/storage.objectAdmin"
```

## 2. Deploy the backend

From the `backend/` directory (it has the `Dockerfile`). Cloud Run sets
`K_SERVICE` automatically, so `NOORAI_STORE` resolves to **firestore** with no
flag. Pass the secrets as env vars (or use Secret Manager):

```bash
cd backend

gcloud run deploy noorai-backend \
  --source . \
  --region asia-south1 \
  --allow-unauthenticated \
  --set-env-vars "OPENAI_API_KEY=sk-...,OPENAI_MODEL=gpt-4o-mini,LLM_PROVIDER=openai,GEMINI_API_KEY=...,NOORAI_VOICE_BUCKET=noorai-voice-notes,ADMIN_TOKEN=$(openssl rand -hex 24)"
```

> Prefer Secret Manager for `OPENAI_API_KEY` / `ADMIN_TOKEN`:
> ```bash
> echo -n "sk-..." | gcloud secrets create openai-api-key --data-file=-
> gcloud run deploy noorai-backend --source . --region asia-south1 \
>   --update-secrets "OPENAI_API_KEY=openai-api-key:latest" \
>   --set-env-vars "LLM_PROVIDER=openai,NOORAI_VOICE_BUCKET=noorai-voice-notes"
> ```

## 3. Verify the deploy

```bash
URL=$(gcloud run services describe noorai-backend --region asia-south1 --format='value(status.url)')
curl -s "$URL/api/health"
# Expect: {"status":"ok","storage":"firestore","llm":{"enabled":true,"provider":"openai",...}}
```

`"storage":"firestore"` confirms data now persists across restarts/redeploys.
`"provider":"openai"` confirms OpenAI is active.

Smoke-test persistence end-to-end:

```bash
# Register, then confirm the user survives a new cold start.
curl -s -X POST "$URL/api/auth/register" \
  -H 'Content-Type: application/json' \
  -d '{"email":"smoke@test.com","password":"password123","name":"Smoke"}'
# -> returns token + refresh_token; the user is now in Firestore.
```

## 4. Admin: switch AI provider at runtime (no redeploy)

```bash
curl -X POST "$URL/api/admin/llm-provider" \
  -H "X-Admin-Token: <ADMIN_TOKEN>" \
  -H 'Content-Type: application/json' \
  -d '{"provider":"gemini"}'   # or "openai", or null to reset to env/auto
```

## 5. Build the mobile app

If the backend URL changes, update `baseUrl` in
`mobile/lib/services/api_service.dart` first.

```bash
cd mobile
flutter pub get
flutter build apk --release          # -> build/app/outputs/flutter-apk/app-release.apk
# Or an app-bundle for the Play Store:
flutter build appbundle --release
```

## Configuration reference (`backend/.env.example`)

| Var | Purpose |
|-----|---------|
| `OPENAI_API_KEY` | Primary AI provider key |
| `LLM_PROVIDER` | `openai` (default) \| `gemini` \| `auto` |
| `GEMINI_API_KEY` | Optional fallback provider |
| `NOORAI_STORE` | `firestore` \| `json` \| unset = auto (Firestore on Cloud Run) |
| `NOORAI_VOICE_BUCKET` | GCS bucket for voice notes (durable audio) |
| `ADMIN_TOKEN` | Secret protecting `/api/admin/*` |
| `NOORAI_OFFLINE_MODE` | `1` to disable LLMs (regex fallback) |

## Security checklist

- [ ] `OPENAI_API_KEY` moved to env/Secret Manager (rotate the one currently in `.env`).
- [ ] `ADMIN_TOKEN` set to a long random value.
- [ ] `.env` is gitignored (it is) — never commit real keys.
- [ ] Firestore security rules: access is via the backend service account only;
      clients never talk to Firestore directly.
