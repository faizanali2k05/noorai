"""Follow-Up Agent — schedules reminders, feedback, progress digests, renewal nudges."""
from __future__ import annotations
from typing import Tuple


def run(booking: dict, therapist: dict) -> Tuple[dict, str]:
    n = len(booking["sessions"])
    events = []
    for i in range(1, n + 1):
        events.append({
            "type": "session_reminder",
            "trigger": "1_hour_before",
            "target_session": i,
            "message_preview": f"{therapist['name']} 1 ghante mein aane wali hain. Tayyar rahen.",
            "status": "scheduled",
        })
        events.append({
            "type": "post_session_feedback",
            "trigger": "30_min_after",
            "target_session": i,
            "prompt": "Session kaisi rahi? 1-5 rate karen.",
            "status": "scheduled",
        })

    events.append({
        "type": "progress_digest",
        "trigger": "after_4_sessions",
        "summary": "Monthly progress check",
        "message_preview": "Aap ke bachay ki therapy progress report tayyar hai.",
        "status": "scheduled",
    })
    events.append({
        "type": "renewal_nudge",
        "trigger": "after_session_8",
        "message_preview": "Aap ki therapy package complete ho rahi hai. Continue karein?",
        "status": "scheduled",
    })

    plan = {"booking_id": booking["booking_id"], "scheduled_events": events}
    reasoning = (
        f"Scheduled {len(events)} follow-up events: "
        f"{n} reminders, {n} feedback prompts, 1 progress digest, 1 renewal nudge."
    )
    return plan, reasoning
