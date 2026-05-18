# NoorAI 🌙

> **Pakistan's First Agentic Special Needs Therapy Marketplace**

*Every child is a light. NoorAI helps families find the right guide.*

NoorAI is an agentic AI system that connects Pakistani families of special-needs children to verified therapists through natural language in Urdu/Roman Urdu/English. It uses an 8-factor intelligent matching engine, dynamic pricing, and fully automated follow-up, all orchestrated by Google Antigravity.

## Architecture

Please see [ARCHITECTURE.md](ARCHITECTURE.md) for a detailed look at the 7 AI Agents powering this platform.

## Setup & Running

**Backend (FastAPI)**
```bash
cd backend
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
uvicorn main:app --reload
```

**Mobile (Flutter)**
```bash
cd mobile
flutter pub get
flutter run
```

## Google Antigravity Integration

Please see [ANTIGRAVITY_WALKTHROUGH.md](ANTIGRAVITY_WALKTHROUGH.md) for screenshots of our Workplan and Tasks Plan as orchestrated by Antigravity.

## Deployment

Check out [deployment.md](deployment.md) for backend deployment instructions.
