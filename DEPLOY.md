# NoorAI — Deployment Guide

- **Backend:** FastAPI on **Render**
- **Database + file storage:** **Supabase** (Postgres + Storage)
- **Mobile:** Flutter (Android)

You only ever give the backend **two secrets** for data — `SUPABASE_URL` and
`SUPABASE_KEY` — plus your AI provider key.

---

## Part 1 — Database (Supabase), one-time · ~3 min

1. Create a project at <https://supabase.com> → **New project**. Pick a region
   close to your users and save the database password somewhere safe.
2. Open **SQL Editor → New query**, paste the **entire** contents of
   [`database.sql`](database.sql), and click **Run**. This creates every table,
   the `voice-notes` storage bucket, indexes, and locks the tables down with
   Row Level Security in one go.
3. Go to **Settings → API** and copy two values — you'll paste them into Render
   in Part 2:
   - **Project URL** → `SUPABASE_URL` (looks like `https://abcd1234.supabase.co`)
   - **service_role** secret key → `SUPABASE_KEY`
     > Use **service_role**, not `anon`. The backend needs full access and the
     > key stays server-side only (never shipped in the app).

That is the entire database setup. You never run SQL again.

---

## Part 2 — Backend (Render)

The backend lives in the [`backend/`](backend/) subfolder and ships with a
[`render.yaml`](render.yaml) Blueprint at the repo root, so Render configures
itself.

### Option A — Blueprint (recommended, one click)

1. Push this repo to GitHub.
2. In Render: **New → Blueprint**, connect the repo. Render reads
   [`render.yaml`](render.yaml) and shows the service `noorai-backend`.
3. It will prompt for the secret env vars. Fill them in:
   | Variable | Value |
   |----------|-------|
   | `SUPABASE_URL` | your Supabase Project URL |
   | `SUPABASE_KEY` | your Supabase **service_role** key |
   | `OPENAI_API_KEY` | `sk-...` (your OpenAI key) |
   | `ADMIN_TOKEN` | any long random string (protects `/api/admin/*`) |
4. Click **Apply**. Render builds and deploys. First build takes ~2–3 min.

### Option B — Manual (Render dashboard, no Blueprint)

1. **New → Web Service**, connect the repo.
2. Set:
   - **Root Directory:** `backend`
   - **Runtime:** Python 3
   - **Build Command:** `pip install -r requirements.txt`
   - **Start Command:** `uvicorn main:app --host 0.0.0.0 --port $PORT`
   - **Health Check Path:** `/api/health`
3. Under **Environment**, add the same variables as the table above, plus
   `PYTHON_VERSION = 3.11.9`, `OPENAI_MODEL = gpt-4o-mini`,
   `LLM_PROVIDER = openai`.
4. **Create Web Service.**

### Verify

Render gives you a URL like `https://noorai-backend.onrender.com`. Check it:

```bash
curl https://noorai-backend.onrender.com/api/health
# → {"status":"ok","storage":"supabase","llm":{"enabled":true,"provider":"openai",...}}
```

`"storage":"supabase"` + `"enabled":true` means Supabase and the AI provider are
both wired up correctly.

> **Free plan note:** Render's free web service sleeps after ~15 min of
> inactivity, so the first request after idle takes ~50 s to wake (cold start).
> Fine for demos; upgrade the instance to keep it always-on.

---

## Part 3 — Mobile app

Point the app at your Render backend — edit the one constant in
[`mobile/lib/services/api_service.dart`](mobile/lib/services/api_service.dart):

```dart
static const String baseUrl = 'https://noorai-backend.onrender.com/api';
```

Then build the APK:

```bash
cd mobile
flutter pub get
flutter build apk --release
```

---

## Local development

```bash
cd backend
python -m venv .venv && .venv\Scripts\activate   # Windows
pip install -r requirements.txt
copy .env.example .env                            # fill in SUPABASE_* + OPENAI_API_KEY
uvicorn main:app --reload
```

The backend talks to the same Supabase project locally, so local and deployed
runs share one database. Set `NOORAI_OFFLINE_MODE=1` to skip the LLM and use the
deterministic regex fallback for an offline demo.
