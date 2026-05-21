"""Antigravity Runner — orchestration core.

This module is the orchestrator that NoorAI registers with Google Antigravity.
Antigravity invokes `run_find_pipeline` and `run_booking_pipeline`; each agent
becomes a node in Antigravity's Workplan and Tasks Plan.

We mirror Antigravity's behavior locally by capturing per-agent traces to
data/traces.json so the mobile app can render the Agent Trace screen even
when running fully offline.
"""
from __future__ import annotations

import json
import time
import uuid
from datetime import datetime
from pathlib import Path
from typing import Any

from agents import (
    intent_agent,
    discovery_agent,
    ranking_agent,
    pricing_agent,
    booking_agent,
    notification_agent,
    followup_agent,
    dispute_agent,
)
from utils import db

DATA_DIR = Path(__file__).resolve().parent.parent / "data"
THERAPISTS_FILE = DATA_DIR / "therapists.json"


def load_therapists() -> list[dict]:
    return json.loads(THERAPISTS_FILE.read_text(encoding="utf-8"))


def _truncate(s: str, n: int = 140) -> str:
    s = str(s)
    return s if len(s) <= n else s[: n - 1] + "…"


def _make_entry(agent: str, started: float, input_payload: Any,
                reasoning: str, output_payload: Any) -> dict:
    duration_ms = int((time.time() - started) * 1000)
    return {
        "agent": agent,
        "started_at": datetime.fromtimestamp(started).astimezone().isoformat(timespec="seconds"),
        "duration_ms": duration_ms,
        "input_summary": _truncate(json.dumps(input_payload, default=str)),
        "reasoning": reasoning,
        "output_summary": _truncate(json.dumps(output_payload, default=str)),
        "output_payload": json.loads(json.dumps(output_payload, default=str)),
    }


def _persist_trace(trace_id: str, user_message: str | None, entries: list[dict]) -> None:
    existing = db.traces.get(trace_id)
    if existing:
        existing["entries"].extend(entries)
        existing["updated_at"] = datetime.now().astimezone().isoformat(timespec="seconds")
        db.traces.put(existing)
    else:
        db.traces.put({
            "trace_id": trace_id,
            "created_at": datetime.now().astimezone().isoformat(timespec="seconds"),
            "user_message": user_message,
            "entries": entries,
        })


def get_trace(trace_id: str) -> dict | None:
    return db.traces.get(trace_id)


# ---------------------------------------------------------------------------
# Pipelines
# ---------------------------------------------------------------------------

def run_find_pipeline(user_message: str) -> dict:
    """Intent -> Discovery -> Ranking -> Pricing (for each top-3).
    Returns dict with intent, ranked, pricing-per-therapist, trace_id."""
    trace_id = f"tr-{uuid.uuid4().hex[:10]}"
    entries: list[dict] = []
    therapists = load_therapists()

    # 1. Intent
    t0 = time.time()
    intent, reasoning = intent_agent.run(user_message)
    intent_dict = intent.model_dump()
    entries.append(_make_entry(
        "Intent Agent", t0, {"user_message": user_message}, reasoning, intent_dict
    ))

    # 2. Discovery
    t0 = time.time()
    candidates, reasoning = discovery_agent.run(intent_dict, therapists)
    entries.append(_make_entry(
        "Discovery Agent", t0,
        {"city": intent_dict["city"], "service": intent_dict["service_type"], "age": intent_dict["child_age"]},
        reasoning,
        {"candidate_count": len(candidates),
         "candidate_ids": [c["id"] for c in candidates]},
    ))

    # 3. Ranking (uses base_price as initial proxy)
    t0 = time.time()
    ranked, reasoning = ranking_agent.run(candidates, intent_dict)
    entries.append(_make_entry(
        "Ranking Agent", t0,
        {"candidate_count": len(candidates), "weights": "8-factor"},
        reasoning,
        {"top_ids": [r["therapist_id"] for r in ranked],
         "top_scores": [r["overall_score"] for r in ranked]},
    ))

    # 4. Pricing per top-3
    t0 = time.time()
    pricing_map = {}
    for r in ranked:
        breakdown, _ = pricing_agent.run(r["therapist"], intent_dict)
        pricing_map[r["therapist_id"]] = breakdown
        # Re-write the price in ranked entry for the UI
        r["price"] = breakdown["final_price"]
    entries.append(_make_entry(
        "Pricing Agent", t0,
        {"therapist_ids": list(pricing_map.keys()), "urgency": intent_dict["urgency"]},
        f"Calculated prices for top {len(pricing_map)} therapists.",
        {tid: pb["final_price"] for tid, pb in pricing_map.items()},
    ))

    _persist_trace(trace_id, user_message, entries)

    # Strip the heavy 'therapist' field from ranked before returning
    ranked_out = [
        {
            "therapist_id": r["therapist_id"],
            "overall_score": r["overall_score"],
            "factor_scores": r["factor_scores"],
            "reasoning": r["reasoning"],
            "distance_km": r["distance_km"],
            "price": r["price"],
            "therapist": r["therapist"],  # mobile app needs the snapshot to render cards
        }
        for r in ranked
    ]

    return {
        "trace_id": trace_id,
        "intent": intent_dict,
        "ranked": ranked_out,
        "pricing": pricing_map,
    }


def run_booking_pipeline(therapist_id: str, slot_iso: str, intent_dict: dict,
                         sessions_count: int = 1, trace_id: str | None = None,
                         user_id: str = "u001") -> dict:
    """Pricing -> Booking -> Notification -> Follow-Up."""
    trace_id = trace_id or f"tr-{uuid.uuid4().hex[:10]}"
    entries: list[dict] = []
    therapists = load_therapists()
    therapist = next((t for t in therapists if t["id"] == therapist_id), None)
    if therapist is None:
        raise ValueError(f"Unknown therapist_id {therapist_id}")

    # Re-price now so booking total is authoritative
    t0 = time.time()
    breakdown, reasoning = pricing_agent.run(therapist, intent_dict)
    entries.append(_make_entry(
        "Pricing Agent", t0,
        {"therapist_id": therapist_id, "urgency": intent_dict.get("urgency")},
        reasoning, breakdown,
    ))

    # Booking
    t0 = time.time()
    booking, reasoning = booking_agent.run(
        therapist, slot_iso, intent_dict,
        price=breakdown["final_price"], sessions_count=sessions_count,
        user_id=user_id,
    )
    entries.append(_make_entry(
        "Booking Agent", t0,
        {"therapist_id": therapist_id, "slot": slot_iso, "sessions_count": sessions_count},
        reasoning, booking,
    ))

    if booking.get("status") == "conflict":
        _persist_trace(trace_id, None, entries)
        return {"trace_id": trace_id, "booking": booking,
                "notifications": None, "followup": None}

    # Notification
    t0 = time.time()
    notifications, reasoning = notification_agent.run(booking, therapist, intent_dict)
    entries.append(_make_entry(
        "Notification Agent", t0,
        {"booking_id": booking["booking_id"]},
        reasoning, notifications,
    ))

    # Follow-up
    t0 = time.time()
    followup, reasoning = followup_agent.run(booking, therapist)
    entries.append(_make_entry(
        "Follow-Up Agent", t0,
        {"booking_id": booking["booking_id"], "sessions": len(booking["sessions"])},
        reasoning, followup,
    ))

    _persist_trace(trace_id, None, entries)

    return {
        "trace_id": trace_id,
        "booking": booking,
        "notifications": notifications,
        "followup": followup,
    }


def run_dispute_pipeline(booking_id: str, reason: str) -> dict:
    trace_id = f"tr-{uuid.uuid4().hex[:10]}"
    entries: list[dict] = []
    therapists = load_therapists()
    booking = booking_agent.get_booking(booking_id)
    if booking is None:
        raise ValueError(f"Unknown booking_id {booking_id}")

    t0 = time.time()
    resolution, reasoning = dispute_agent.run(booking, reason, therapists)
    entries.append(_make_entry(
        "Dispute Agent", t0,
        {"booking_id": booking_id, "reason": reason},
        reasoning, resolution,
    ))
    _persist_trace(trace_id, None, entries)

    alt = None
    alt_id = resolution.get("alternative_therapist_id")
    if alt_id:
        alt_t = next((t for t in therapists if t["id"] == alt_id), None)
        if alt_t:
            alt = {
                "therapist_id": alt_t["id"],
                "name": alt_t["name"],
                "rating": alt_t["rating"],
                "distance_km": resolution.get("alternative", {}).get("distance_km", 0.0),
                "qualifications": alt_t["qualifications"][0],
                "verified": alt_t["verified"],
                "price": resolution.get("alternative", {}).get("price"),
                "slot": resolution.get("alternative", {}).get("slot"),
            }

    return {"trace_id": trace_id, "resolution": resolution, "alternative": alt}


# ---------------------------------------------------------------------------
# Baseline (traditional distance-only)
# ---------------------------------------------------------------------------

def run_baseline(user_message: str) -> dict:
    """Traditional algorithm: city filter + sort by distance, ignore everything else."""
    from utils.geo import resolve_user_location, haversine_km

    intent, _ = intent_agent.run(user_message)
    intent_dict = intent.model_dump()
    therapists = load_therapists()

    in_city = [t for t in therapists if intent_dict.get("city") and t["city"] == intent_dict["city"]]
    user_loc = resolve_user_location(intent_dict.get("city"), intent_dict.get("area"))
    if user_loc:
        for t in in_city:
            t["distance_km"] = round(haversine_km(user_loc[0], user_loc[1], t["lat"], t["lng"]), 2)
    else:
        for t in in_city:
            t["distance_km"] = 0.0
    in_city.sort(key=lambda t: t["distance_km"])
    traditional_top = in_city[:3]

    ai_result = run_find_pipeline(user_message)
    return {
        "intent": intent_dict,
        "traditional": [
            {
                "therapist_id": t["id"],
                "name": t["name"],
                "distance_km": t["distance_km"],
                "specializations": t["specializations"],
                "rating": t["rating"],
                "price": t["base_price"],
                "verified": t["verified"],
            }
            for t in traditional_top
        ],
        "ai": ai_result["ranked"],
        "ai_trace_id": ai_result["trace_id"],
    }
