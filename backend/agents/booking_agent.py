"""Booking Agent — books a therapist with an optimistic slot lock.

Bookings persist via the shared store (``utils.db``) and are owned by the
authenticated ``user_id`` so each parent only ever sees their own bookings.
"""
from __future__ import annotations

import secrets
from datetime import datetime, timedelta
from typing import Tuple

from utils import db


def _load_bookings() -> list[dict]:
    return db.bookings.all()


def _slot_taken(therapist_id: str, slot_iso: str, bookings: list[dict]) -> bool:
    for b in bookings:
        if b["therapist_id"] != therapist_id:
            continue
        if b["status"] in ("user_cancelled", "therapist_cancelled"):
            continue
        for s in b["sessions"]:
            if f"{s['date']}T{s['time']}:00" == slot_iso:
                return True
    return False


def _gen_confirmation_code(therapist_name: str) -> str:
    cleaned = therapist_name.replace("Dr.", "").replace("Ms.", "").replace("Mr.", "")
    initials = "".join(w[0] for w in cleaned.split()[:3]).upper() or "NA"
    suffix = "".join(secrets.choice("0123456789") for _ in range(4))
    return f"NA-{initials}-{suffix}"


def _expand_sessions(first_slot_iso: str, count: int, frequency: str) -> list[dict]:
    dt = datetime.fromisoformat(first_slot_iso)
    gap_days = {"weekly": 7, "biweekly": 3, "thrice_weekly": 2, "one_time": 7}.get(frequency, 7)
    sessions = []
    for i in range(count):
        s_dt = dt + timedelta(days=i * gap_days)
        sessions.append({
            "date": s_dt.date().isoformat(),
            "time": s_dt.strftime("%H:%M"),
            "duration_min": 45,
            "status": "confirmed",
        })
    return sessions


def run(therapist: dict, slot_iso: str, intent_dict: dict, price: int,
        sessions_count: int = 1, user_id: str = "u001") -> Tuple[dict, str]:
    bookings = _load_bookings()

    if _slot_taken(therapist["id"], slot_iso, bookings):
        next_slots = [s for s in therapist["available_slots"]
                      if not _slot_taken(therapist["id"], s, bookings)]
        suggestion = next_slots[0] if next_slots else None
        reasoning = (
            f"Slot {slot_iso} already taken for {therapist['name']}. "
            f"Suggested next: {suggestion}."
        )
        return {
            "status": "conflict",
            "suggested_slot": suggestion,
            "therapist_id": therapist["id"],
        }, reasoning

    frequency = intent_dict.get("frequency", "one_time")
    sessions = _expand_sessions(slot_iso, sessions_count, frequency)
    total = price * sessions_count

    today = datetime.now().strftime("%Y%m%d")
    booking = {
        "booking_id": f"BK-{today}-{secrets.token_hex(3)}",
        "therapist_id": therapist["id"],
        "user_id": user_id,
        "sessions": sessions,
        "total_price": total,
        "confirmation_code": _gen_confirmation_code(therapist["name"]),
        "status": "confirmed",
        "created_at": datetime.now().astimezone().isoformat(timespec="seconds"),
        "intent_snapshot": intent_dict,
    }
    db.bookings.put(booking)

    reasoning = (
        f"Booked {therapist['name']} for {sessions_count} session(s) starting {slot_iso}. "
        f"Total Rs {total}. Code {booking['confirmation_code']}."
    )
    return booking, reasoning


def update_status(booking_id: str, new_status: str) -> dict | None:
    return db.bookings.update(booking_id, {"status": new_status})


def get_booking(booking_id: str) -> dict | None:
    return db.bookings.get(booking_id)
