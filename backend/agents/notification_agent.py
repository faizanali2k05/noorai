"""Notification Agent — generates mock WhatsApp messages (no real send)."""
from __future__ import annotations

from datetime import datetime
from typing import Tuple


def _format_date_urdu(date_iso: str, time_str: str) -> str:
    months_roman = ["Jan", "Feb", "March", "April", "May", "June",
                    "July", "Aug", "Sept", "Oct", "Nov", "Dec"]
    d = datetime.fromisoformat(date_iso)
    return f"{d.day} {months_roman[d.month-1]}, {time_str}"


def run(booking: dict, therapist: dict, intent_dict: dict) -> Tuple[dict, str]:
    first = booking["sessions"][0]
    first_str = _format_date_urdu(first["date"], first["time"])
    n_sessions = len(booking["sessions"])
    code = booking["confirmation_code"]
    total = booking["total_price"]
    area = intent_dict.get("area") or therapist.get("area", "")
    city = intent_dict.get("city") or therapist.get("city", "")

    parent_msg = (
        f"Salam! Aap ka booking confirm ho gaya hai. {therapist['name']} "
        f"({therapist['specializations'][0].replace('_', ' ').title()}) "
        f"{first_str} ko aap ke ghar aayegi. "
        f"Confirmation code: {code}. Total: Rs {total} ({n_sessions} session{'s' if n_sessions > 1 else ''}). "
        f"Cancel/reschedule: app khol kar 'My Bookings' mein jaayen."
    )

    age = intent_dict.get("child_age") or "?"
    condition = (intent_dict.get("condition") or "general").replace("_", " ")
    therapist_msg = (
        f"Hi {therapist['name']}, you have a new confirmed booking. "
        f"Patient: child (age {age}, {condition}). "
        f"Address: {area}, {city}. "
        f"First session: {first_str}. "
        f"Total sessions: {n_sessions}. Family contact will be shared 1 hour before."
    )

    payload = {
        "to_parent": {
            "channel": "whatsapp",
            "language": "roman_urdu",
            "message": parent_msg,
        },
        "to_therapist": {
            "channel": "whatsapp",
            "language": "english",
            "message": therapist_msg,
        },
    }
    reasoning = (
        f"Generated 2 WhatsApp messages: Roman Urdu for parent, English for therapist. "
        f"Confirmation code {code}."
    )
    return payload, reasoning
