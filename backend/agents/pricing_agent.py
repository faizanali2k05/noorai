"""Pricing Agent — dynamic per-session price with full breakdown."""
from __future__ import annotations
from typing import Tuple

URGENCY_MULT = {"scheduled": 1.0, "next_day": 1.15, "same_day": 1.3, "immediate": 1.5}


def _complexity(intent_dict: dict) -> tuple[float, str]:
    condition = intent_dict.get("condition")
    # Spec: autism+adhd combo = 1.4, single severe = 1.2, basic = 1.0
    severe = {"autism", "cerebral_palsy", "down_syndrome", "adhd"}
    # We only carry one condition field; treat severe ones as 1.2
    if condition in severe:
        return 1.2, f"single complex condition ({condition})"
    return 1.0, "standard complexity"


def _loyalty_discount(sessions_completed: int) -> tuple[float, str]:
    if sessions_completed >= 30:
        return 0.15, "30+ sessions loyalty"
    if sessions_completed >= 15:
        return 0.10, "15+ sessions loyalty"
    if sessions_completed >= 5:
        return 0.05, "5+ sessions loyalty"
    return 0.0, "new user"


def run(therapist: dict, intent_dict: dict, sessions_completed: int = 0
        ) -> Tuple[dict, str]:
    base = therapist["base_price"]
    dist = therapist.get("distance_km", 0.0)
    surcharge = int(max(0, (dist - 3)) * 100)
    urgency_mult = URGENCY_MULT[intent_dict.get("urgency", "scheduled")]
    complexity_mult, complexity_note = _complexity(intent_dict)
    loyalty_pct, loyalty_note = _loyalty_discount(sessions_completed)

    subtotal = int((base + surcharge) * urgency_mult * complexity_mult)
    loyalty_discount = int(subtotal * loyalty_pct)
    final = subtotal - loyalty_discount

    explanation = (
        f"Base Rs {base} + Rs {surcharge} distance × {urgency_mult} urgency "
        f"× {complexity_mult} complexity − Rs {loyalty_discount} loyalty = Rs {final}"
    )

    breakdown = {
        "base_rate": base,
        "distance_surcharge": surcharge,
        "urgency_multiplier": urgency_mult,
        "complexity_multiplier": complexity_mult,
        "subtotal": subtotal,
        "loyalty_discount": loyalty_discount,
        "final_price": final,
        "breakdown_explanation": explanation,
    }
    reasoning = (
        f"Priced {therapist['name']}: base {base}, urgency {urgency_mult}×, "
        f"{complexity_note} ({complexity_mult}×), {loyalty_note}. Final Rs {final}."
    )
    return breakdown, reasoning
