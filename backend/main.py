"""NoorAI FastAPI backend — exposes the agent pipeline as HTTP."""
from __future__ import annotations

import os
import secrets
from pathlib import Path
from typing import Optional

from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException, UploadFile, File, Form, Header
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import Response
from pydantic import BaseModel, EmailStr, Field, field_validator

load_dotenv(Path(__file__).resolve().parent / ".env")

from models.schemas import (
    FindRequest, FindResponse,
    BookingRequest, BookingResponse,
    DisputeRequest, DisputeResponse,
)
from orchestrator import antigravity_runner as orch
from orchestrator import services_runner as services
from agents import booking_agent
from utils import users as users_store
from utils import chat as chat_store
from utils import llm
from utils import db

app = FastAPI(title="NoorAI Backend", version="1.1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


# ── Health ────────────────────────────────────────────────────────────────

@app.get("/")
def root():
    return {"name": "NoorAI Backend", "status": "ok",
            "offline_mode": os.environ.get("NOORAI_OFFLINE_MODE") == "1",
            "storage": db.backend_name(),
            "llm": llm.llm_status()}


@app.get("/api/health")
def health():
    """Verifiable health check — confirms the active LLM provider and storage backend."""
    return {"status": "ok", "storage": db.backend_name(), "llm": llm.llm_status()}


# ── Agent pipeline endpoints (unchanged) ──────────────────────────────────

@app.post("/api/find-therapists")
def find_therapists(req: FindRequest):
    return orch.run_find_pipeline(req.user_message)


@app.post("/api/book")
def book(req: BookingRequest, authorization: Optional[str] = Header(default=None)):
    user = _require_user(authorization)
    return orch.run_booking_pipeline(
        therapist_id=req.therapist_id,
        slot_iso=req.slot,
        intent_dict=req.intent.model_dump(),
        sessions_count=req.sessions_count,
        trace_id=req.trace_id,
        user_id=user["user_id"],
    )


@app.get("/api/trace/{trace_id}")
def get_trace(trace_id: str):
    trace = orch.get_trace(trace_id)
    if trace is None:
        raise HTTPException(status_code=404, detail="Trace not found")
    return trace


@app.post("/api/dispute")
def dispute(req: DisputeRequest):
    try:
        return orch.run_dispute_pipeline(req.booking_id, req.reason)
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))


@app.post("/api/baseline-compare")
def baseline_compare(req: FindRequest):
    return orch.run_baseline(req.user_message)


# ── General home-services pipeline (plumber, electrician, AC, tutor, …) ─────

class FindServicesRequest(BaseModel):
    user_message: str


class BookServiceRequest(BaseModel):
    provider_id: str
    slot: Optional[str] = None
    intent: dict = {}
    trace_id: Optional[str] = None


@app.get("/api/service-categories")
def service_categories():
    return {"categories": [{"id": k, "label": v} for k, v in services.CATEGORIES.items()]}


@app.post("/api/find-services")
def find_services(req: FindServicesRequest):
    return services.run_find_services(req.user_message)


@app.post("/api/book-service")
def book_service(req: BookServiceRequest, authorization: Optional[str] = Header(default=None)):
    user = _require_user(authorization)
    try:
        return services.run_book_service(
            req.provider_id, req.slot, req.intent, req.trace_id, user_id=user["user_id"]
        )
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))


def _require_admin(x_admin_token: Optional[str]) -> None:
    expected = os.environ.get("ADMIN_TOKEN")
    if not expected:
        raise HTTPException(status_code=503, detail="Admin actions are disabled (ADMIN_TOKEN not set)")
    if not x_admin_token or not secrets.compare_digest(x_admin_token, expected):
        raise HTTPException(status_code=403, detail="Admin authorization required")


class LLMProviderIn(BaseModel):
    provider: Optional[str] = None  # "openai" | "gemini" | null (reset to env/auto)


@app.get("/api/admin/llm-provider")
def admin_get_llm(x_admin_token: Optional[str] = Header(default=None)):
    _require_admin(x_admin_token)
    return {"status": "ok", "llm": llm.llm_status()}


@app.post("/api/admin/llm-provider")
def admin_set_llm(req: LLMProviderIn, x_admin_token: Optional[str] = Header(default=None)):
    """Admin switch for the active AI provider. OpenAI is the default; this lets
    an admin force a provider at runtime without a redeploy."""
    _require_admin(x_admin_token)
    try:
        llm.set_provider(req.provider)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    return {"status": "ok", "llm": llm.llm_status()}


@app.post("/api/admin/cancel-therapist/{booking_id}")
def admin_cancel(booking_id: str, x_admin_token: Optional[str] = Header(default=None)):
    _require_admin(x_admin_token)
    b = booking_agent.update_status(booking_id, "therapist_cancelled")
    if b is None:
        raise HTTPException(status_code=404, detail="Booking not found")
    return {"status": "ok", "booking_id": booking_id, "new_status": "therapist_cancelled"}


@app.get("/api/booking-status/{booking_id}")
def booking_status(booking_id: str):
    b = booking_agent.get_booking(booking_id)
    if b is None:
        raise HTTPException(status_code=404, detail="Booking not found")
    return {"booking_id": booking_id, "status": b["status"]}


# ── Auth ──────────────────────────────────────────────────────────────────

class RegisterIn(BaseModel):
    email: EmailStr
    password: str = Field(min_length=8, max_length=128)
    name: str = Field(min_length=1, max_length=80)

    @field_validator("name")
    @classmethod
    def _name_not_blank(cls, v: str) -> str:
        v = v.strip()
        if not v:
            raise ValueError("Name cannot be empty")
        return v


class LoginIn(BaseModel):
    email: EmailStr
    password: str = Field(min_length=1, max_length=128)
    remember: bool = False


class RefreshIn(BaseModel):
    refresh_token: str


class LogoutIn(BaseModel):
    refresh_token: Optional[str] = None


class ProfilePatch(BaseModel):
    name: Optional[str] = None
    phone: Optional[str] = None
    child_name: Optional[str] = None
    child_age: Optional[int] = None
    child_condition: Optional[str] = None
    city: Optional[str] = None
    area: Optional[str] = None


def _bearer(authorization: Optional[str]) -> Optional[str]:
    if authorization and authorization.lower().startswith("bearer "):
        return authorization[7:].strip()
    return None


def _require_user(authorization: Optional[str]) -> dict:
    user = users_store.user_from_token(_bearer(authorization))
    if not user:
        raise HTTPException(status_code=401, detail="Not authenticated")
    return user


@app.post("/api/auth/register")
def auth_register(req: RegisterIn):
    result, err = users_store.register(req.email, req.password, req.name)
    if err:
        raise HTTPException(status_code=400, detail=err)
    return result


@app.post("/api/auth/login")
def auth_login(req: LoginIn):
    result, err = users_store.login(req.email, req.password, remember=req.remember)
    if err:
        raise HTTPException(status_code=401, detail=err)
    return result


@app.post("/api/auth/refresh")
def auth_refresh(req: RefreshIn):
    result, err = users_store.refresh_session(req.refresh_token)
    if err:
        raise HTTPException(status_code=401, detail=err)
    return result


@app.post("/api/auth/logout")
def auth_logout(req: LogoutIn, authorization: Optional[str] = Header(default=None)):
    users_store.revoke_session(_bearer(authorization), req.refresh_token)
    return {"status": "ok"}


@app.get("/api/auth/me")
def auth_me(authorization: Optional[str] = Header(default=None)):
    return _require_user(authorization)


@app.patch("/api/auth/me")
def auth_update(patch: ProfilePatch, authorization: Optional[str] = Header(default=None)):
    user = _require_user(authorization)
    updated = users_store.update_profile(user["user_id"], patch.model_dump(exclude_none=True))
    if not updated:
        raise HTTPException(status_code=404, detail="User not found")
    return updated


# ── Bookings list (per-user) ──────────────────────────────────────────────

@app.get("/api/bookings")
def list_bookings(authorization: Optional[str] = Header(default=None)):
    user = _require_user(authorization)
    mine = [b for b in booking_agent._load_bookings()  # noqa: SLF001
            if b.get("user_id") == user["user_id"]]
    mine.sort(key=lambda b: b.get("created_at", ""), reverse=True)
    return {"bookings": mine}


# ── Chat ──────────────────────────────────────────────────────────────────

class SendTextIn(BaseModel):
    text: str


@app.get("/api/chats")
def list_chat_threads(authorization: Optional[str] = Header(default=None)):
    user = _require_user(authorization)
    return {"threads": chat_store.list_threads_for_user(user["user_id"])}


@app.get("/api/chats/{therapist_id}")
def get_chat(therapist_id: str, authorization: Optional[str] = Header(default=None)):
    user = _require_user(authorization)
    return {"messages": chat_store.list_messages(user["user_id"], therapist_id)}


@app.post("/api/chats/{therapist_id}")
def send_chat_text(therapist_id: str, req: SendTextIn,
                   authorization: Optional[str] = Header(default=None)):
    user = _require_user(authorization)
    text = req.text.strip()
    if not text:
        raise HTTPException(status_code=400, detail="Empty message")
    if len(text) > 4000:
        raise HTTPException(status_code=413, detail="Message too long (max 4000 characters)")
    return chat_store.send_text(user["user_id"], therapist_id, text, sender="user")


@app.post("/api/chats/{therapist_id}/voice")
async def send_chat_voice(
    therapist_id: str,
    voice: UploadFile = File(...),
    duration_ms: int = Form(...),
    authorization: Optional[str] = Header(default=None),
):
    user = _require_user(authorization)
    data = await voice.read()
    if not data:
        raise HTTPException(status_code=400, detail="Empty voice file")
    if len(data) > 8 * 1024 * 1024:
        raise HTTPException(status_code=413, detail="Voice note too large (max 8MB)")
    ext = (voice.filename or "voice.m4a").rsplit(".", 1)[-1].lower()
    if ext not in ("m4a", "mp3", "aac", "wav", "ogg", "opus"):
        ext = "m4a"
    filename = chat_store.save_voice_file(data, ext=ext)
    return chat_store.send_voice(user["user_id"], therapist_id, filename, duration_ms, sender="user")


@app.get("/api/voice-notes/{filename}")
def get_voice_note(filename: str):
    data = chat_store.load_voice(filename)
    if data is None:
        raise HTTPException(status_code=404, detail="Voice note not found")
    return Response(content=data, media_type="audio/mp4")
