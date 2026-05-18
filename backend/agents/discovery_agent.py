"""Discovery Agent — filters therapists by city, specialization, age range, distance."""
from __future__ import annotations

from typing import Tuple
from utils.geo import haversine_km, resolve_user_location
from utils.scoring import age_bucket


def _matches_specialization(intent_service: str | None, t_specs: list[str]) -> bool:
    if not intent_service:
        return True
    if intent_service in t_specs:
        return True
    # Tolerate related specs at discovery stage (let ranking handle quality)
    return False


def _matches_age_range(child_age: int | None, t_ranges: list[str]) -> bool:
    if child_age is None:
        return True
    return age_bucket(child_age) in t_ranges


def run(intent_dict: dict, all_therapists: list[dict],
        exclude_ids: list[str] | None = None) -> Tuple[list[dict], str]:
    exclude_ids = set(exclude_ids or [])
    city = intent_dict.get("city")
    area = intent_dict.get("area")
    service = intent_dict.get("service_type")
    child_age = intent_dict.get("child_age")

    user_loc = resolve_user_location(city, area)

    def _enrich(t: dict) -> dict:
        if user_loc:
            dist = haversine_km(user_loc[0], user_loc[1], t["lat"], t["lng"])
        else:
            dist = 0.0
        return {**t, "distance_km": round(dist, 2)}

    # Phase 1: strict city + service + age + within 5 km
    candidates = []
    for t in all_therapists:
        if t["id"] in exclude_ids:
            continue
        if city and t["city"] != city:
            continue
        if not _matches_specialization(service, t["specializations"]):
            continue
        if not _matches_age_range(child_age, t["age_ranges"]):
            continue
        enriched = _enrich(t)
        if enriched["distance_km"] <= 5.0 or user_loc is None:
            candidates.append(enriched)

    # Phase 2: expand to 15 km if no results
    expanded = False
    if not candidates:
        expanded = True
        for t in all_therapists:
            if t["id"] in exclude_ids:
                continue
            if city and t["city"] != city:
                continue
            if service and service not in t["specializations"]:
                continue
            enriched = _enrich(t)
            if enriched["distance_km"] <= 15.0:
                candidates.append(enriched)

    reasoning = (
        f"Filtered {len(all_therapists)} therapists by city={city}, service={service}, "
        f"age={child_age}. Found {len(candidates)} candidates"
        + (" (expanded to 15km radius)." if expanded else " within 5km.")
    )
    return candidates, reasoning
