"""Dispute Agent — handles cancellation, no-show, complaint, price dispute.

On therapist_cancelled, autonomously re-runs Discovery + Ranking excluding the canceller
and proposes a same-slot alternative.
"""
from __future__ import annotations

from typing import Tuple
from agents import discovery_agent, ranking_agent, pricing_agent, booking_agent


def _has_slot(therapist: dict, slot_iso: str) -> bool:
    return slot_iso in therapist.get("available_slots", [])


def run(booking: dict, reason: str, all_therapists: list[dict]) -> Tuple[dict, str]:
    if reason == "therapist_cancelled":
        return _handle_therapist_cancelled(booking, all_therapists)
    if reason == "no_show":
        return _handle_no_show(booking, all_therapists)
    if reason == "price_dispute":
        return ({
            "action": "complaint_logged",
            "booking_id": booking["booking_id"],
            "user_message": "Aap ki price shikayat record kar li gayi hai. NoorAI team 24 ghante mein contact karegi.",
        }, "Logged price dispute for manual review.")
    if reason == "user_cancel":
        booking_agent.update_status(booking["booking_id"], "user_cancelled")
        return ({
            "action": "refund_initiated",
            "booking_id": booking["booking_id"],
            "user_message": "Aap ka booking cancel ho gaya. Refund 3-5 business days mein process hoga.",
        }, "User-initiated cancellation accepted; refund initiated.")
    # default complaint
    return ({
        "action": "complaint_logged",
        "booking_id": booking["booking_id"],
        "user_message": "Aap ki shikayat record ho gayi hai. NoorAI team review karegi.",
    }, f"Logged complaint reason={reason}.")


def _handle_therapist_cancelled(booking: dict, all_therapists: list[dict]) -> Tuple[dict, str]:
    booking_agent.update_status(booking["booking_id"], "therapist_cancelled")

    intent = booking.get("intent_snapshot") or {}
    cancelled_id = booking["therapist_id"]
    first_session = booking["sessions"][0]
    target_slot = f"{first_session['date']}T{first_session['time']}:00"

    candidates, _ = discovery_agent.run(intent, all_therapists, exclude_ids=[cancelled_id])
    if not candidates:
        return ({
            "action": "reschedule_required",
            "booking_id": booking["booking_id"],
            "user_message": "Koi available alternative therapist nahi mila. Hum aap se 1 ghante mein contact karenge.",
        }, "No alternative candidates available; manual reschedule required.")

    ranked, _ = ranking_agent.run(candidates, intent)
    top = ranked[0]
    top_t = top["therapist"]
    has_slot = _has_slot(top_t, target_slot)

    if has_slot:
        cancelled_name = next((t["name"] for t in all_therapists if t["id"] == cancelled_id), "Therapist")
        price_breakdown, _ = pricing_agent.run(top_t, intent)
        return ({
            "action": "auto_rebook_proposed",
            "booking_id": booking["booking_id"],
            "alternative_therapist_id": top_t["id"],
            "alternative": {
                "therapist_id": top_t["id"],
                "name": top_t["name"],
                "rating": top_t["rating"],
                "distance_km": top["distance_km"],
                "qualifications": top_t["qualifications"][0],
                "verified": top_t["verified"],
                "price": price_breakdown["final_price"],
                "slot": target_slot,
            },
            "user_message": (
                f"{cancelled_name} ne cancel kar diya. Hum ne {top_t['name']} "
                f"({top_t['rating']}★, {top['distance_km']}km) ko same slot ke liye dhoondh liya. "
                f"Confirm karne ke liye tap karein."
            ),
            "compensation": "10% discount on next session",
        }, f"Dispute Agent re-ran Discovery+Ranking; proposed {top_t['name']} for same slot.")

    # Otherwise: top 3 alternatives, user picks
    alts = []
    for r in ranked[:3]:
        pb, _ = pricing_agent.run(r["therapist"], intent)
        alts.append({
            "therapist_id": r["therapist_id"],
            "name": r["therapist"]["name"],
            "rating": r["therapist"]["rating"],
            "distance_km": r["distance_km"],
            "next_available": r["therapist"]["available_slots"][0],
            "price": pb["final_price"],
        })
    return ({
        "action": "reschedule_required",
        "booking_id": booking["booking_id"],
        "alternatives": alts,
        "user_message": "Same slot par koi available nahi. Yeh top 3 options dekh kar choose karein.",
        "compensation": "10% discount on next session",
    }, f"No same-slot match; surfaced top 3 alternatives.")


def _handle_no_show(booking: dict, all_therapists: list[dict]) -> Tuple[dict, str]:
    # Treat same as therapist cancelled but log differently
    res, reasoning = _handle_therapist_cancelled(booking, all_therapists)
    res["user_message"] = "Therapist nahi aaye. " + res["user_message"]
    return res, "No-show handled: " + reasoning
