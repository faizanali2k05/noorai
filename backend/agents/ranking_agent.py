"""Ranking Agent — applies 8-factor weighted scoring per spec §6.3."""
from __future__ import annotations

from typing import Tuple
from utils.scoring import compute_factor_scores, compute_overall, WEIGHTS


def _build_reasoning(t: dict, fs: dict, overall: float, distance_km: float) -> str:
    qual = t["qualifications"][0] if t["qualifications"] else "qualified"
    verified = "verified" if t["verified"] else "unverified"
    fits = f"fits budget" if fs["price"] >= 0.85 else (
        "slightly over budget" if fs["price"] >= 0.5 else "over budget"
    )
    return (
        f"{qual} ({verified}); {distance_km}km away; {t['rating']}★ ({t['review_count']} reviews); "
        f"{int(t['on_time_rate']*100)}% on-time; {fits}. Score {overall:.2f}."
    )


def run(candidates: list[dict], intent_dict: dict, prices: dict[str, int] | None = None
        ) -> Tuple[list[dict], str]:
    if not candidates:
        return [], "No candidates to rank."

    prices = prices or {}
    ranked = []
    for t in candidates:
        price = prices.get(t["id"], t["base_price"])
        dist = t.get("distance_km", 0.0)
        fs = compute_factor_scores(t, intent_dict, dist, price)
        overall = compute_overall(fs, t, intent_dict)
        ranked.append({
            "therapist_id": t["id"],
            "overall_score": overall,
            "factor_scores": fs,
            "reasoning": _build_reasoning(t, fs, overall, dist),
            "distance_km": dist,
            "price": price,
            "therapist": t,  # keep full record for downstream agents
        })

    ranked.sort(key=lambda r: r["overall_score"], reverse=True)
    top = ranked[:3]

    reasoning = (
        f"Scored {len(ranked)} candidates across 8 factors "
        f"(weights: {WEIGHTS}). Top match: {top[0]['therapist']['name']} "
        f"with overall {top[0]['overall_score']:.2f}."
    )
    return top, reasoning
