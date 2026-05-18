"""NoorAI FastAPI backend — exposes the agent pipeline as HTTP."""
from __future__ import annotations

import os
from pathlib import Path

from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware

load_dotenv(Path(__file__).resolve().parent / ".env")

from models.schemas import (
    FindRequest, FindResponse,
    BookingRequest, BookingResponse,
    DisputeRequest, DisputeResponse,
)
from orchestrator import antigravity_runner as orch
from agents import booking_agent

app = FastAPI(title="NoorAI Backend", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/")
def root():
    return {"name": "NoorAI Backend", "status": "ok",
            "offline_mode": os.environ.get("NOORAI_OFFLINE_MODE") == "1"}


@app.post("/api/find-therapists")
def find_therapists(req: FindRequest):
    result = orch.run_find_pipeline(req.user_message)
    return result


@app.post("/api/book")
def book(req: BookingRequest):
    result = orch.run_booking_pipeline(
        therapist_id=req.therapist_id,
        slot_iso=req.slot,
        intent_dict=req.intent.model_dump(),
        sessions_count=req.sessions_count,
        trace_id=req.trace_id,
    )
    return result


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


# --- Demo / stress test endpoints ----------------------------------------

@app.post("/api/admin/cancel-therapist/{booking_id}")
def admin_cancel(booking_id: str):
    """Simulates the therapist cancelling. Polled by the app to trigger Dispute Agent."""
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
