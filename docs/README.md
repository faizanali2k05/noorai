# NoorAI — Pakistan's First Agentic Special Needs Therapy Marketplace

> *Every child is a light. NoorAI helps families find the right guide.*  
> Built for Google Antigravity Hackathon — Challenge 2.

## The Problem
350,000+ children in Pakistan are on the autism spectrum. Furthermore, disabled individuals struggle to find reliable support like accessible transport, home nursing, sign language interpreters, and wheelchair repair. Most families find these services through WhatsApp groups and Facebook posts with no quality signals, no matching, and no follow-up.

## The Solution
NoorAI is a 7-agent agentic system that takes a natural language request in Urdu, Roman Urdu, or English — and within seconds delivers a ranked, priced, and booked service session with full follow-up automation. The core prominent feature of the application is the targeted demographic: **disabled individuals and their families**.

## Architecture
See `docs/ARCHITECTURE.md` for the system diagram and component breakdown.

## Google Antigravity — Core Orchestration
NoorAI uses Antigravity as its **primary orchestration layer**, not as an add-on:
- All 7 agents are registered and executed inside Antigravity
- Each request generates an **Antigravity Workplan** (screenshot: `/docs/antigravity/workplan.png`)
- Each agent execution generates a **Tasks Plan** (screenshot: `/docs/antigravity/tasks_plan.png`)
- Agent Artifacts are exported and stored in `/docs/antigravity/artifacts/`
- Reasoning steps, decision flow, and action execution all flow through Antigravity

See `docs/ANTIGRAVITY_WALKTHROUGH.md` for a deeper dive into the Antigravity implementation.

## 7 Agents Pipeline
1. **Intent Agent** — Multilingual NLP (Urdu/Roman Urdu/English) → structured intent
2. **Discovery Agent** — Filter mock DB by city, specialization, age range, radius
3. **Ranking Agent** — 8-factor weighted scoring with per-factor transparency
4. **Pricing Agent** — Dynamic pricing with full breakdown
5. **Booking Agent** — Simulated booking; writes to bookings.json
6. **Follow-Up Agent** — 5-event reminder/feedback schedule
7. **Dispute Agent** — Auto-recovery on cancellation; re-runs discovery pipeline autonomously

## Tech Stack
- Flutter (mobile app, Material 3)
- Python 3.11 + FastAPI (backend)
- Google Antigravity (orchestration — mandatory core)
- Gemini 2.0 Flash (LLM)
- JSON flat files (mock data store)

## Running Locally
1. Backend: `cd backend && pip install -r requirements.txt && uvicorn main:app --reload`
2. Mobile: `cd mobile && flutter run`

## Assumptions
- Mock provider data (no real PII)
- Simulated bookings and WhatsApp notifications
- Single user per device (no auth in MVP)
- Locations approximate (Haversine against area centroids)

## Compliance
- ✅ No real personal data
- ✅ Disclaimer: "NoorAI connects families with therapists and disability support providers. It does not provide medical diagnosis."
- ✅ All mock
- ✅ Focus on disabled people support
