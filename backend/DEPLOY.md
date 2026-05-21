# NoorAI Backend — Deploy & Realtime LLM

The mobile app calls the live Cloud Run service:
`https://noorai-backend-485583022901.asia-south1.run.app/api`

## Realtime LLM (OpenAI)

Natural-language understanding (intent parsing for both special-needs therapy
and general home services) runs on **OpenAI** by default:

- `OPENAI_API_KEY` — your key (required for realtime parsing)
- `OPENAI_MODEL` — defaults to `gpt-4o-mini`
- If no `OPENAI_API_KEY` is set, the system falls back to `GEMINI_API_KEY`,
  then to a deterministic regex parser, so the demo always works.
- `NOORAI_OFFLINE_MODE=1` disables all LLM calls (regex only).

Verify which provider is live at any time:

```
GET /api/health   ->  {"status":"ok","llm":{"enabled":true,"provider":"openai","model":"gpt-4o-mini"}}
```

> The key lives only in `backend/.env` locally (gitignored) and is **excluded
> from the Docker image** via `.dockerignore`. In production it is supplied as a
> Cloud Run environment variable — never committed.

## Redeploy to Cloud Run

`gcloud` is required (not bundled in this repo). From the `backend/` folder:

```powershell
./deploy.ps1 -OpenAiKey "sk-proj-..."
```

or directly:

```bash
gcloud run deploy noorai-backend \
  --source . \
  --region asia-south1 \
  --allow-unauthenticated \
  --set-env-vars "OPENAI_API_KEY=sk-proj-...,OPENAI_MODEL=gpt-4o-mini,NOORAI_OFFLINE_MODE=0"
```

To only update the key on the existing service (no code rebuild):

```bash
gcloud run services update noorai-backend --region asia-south1 \
  --update-env-vars "OPENAI_API_KEY=sk-proj-...,OPENAI_MODEL=gpt-4o-mini"
```

## Run locally

```bash
cd backend
pip install -r requirements.txt
uvicorn main:app --reload --port 8080
```

Point the app at your machine by editing `mobile/lib/services/api_service.dart`
(`baseUrl`) — use `http://10.0.2.2:8080/api` for the Android emulator.

## Endpoints added for the home-services flow

- `GET  /api/service-categories` — the 10 supported categories
- `POST /api/find-services` — NL → intent → discovery → ranking (with trace)
- `POST /api/book-service` — simulated booking → confirmation → follow-up
