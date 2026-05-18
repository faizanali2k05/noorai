"""8-factor weighted scoring per NoorAI spec §6.3."""
from __future__ import annotations
from typing import Optional

# Service-to-related-spec map (for partial matches)
RELATED_SPECS = {
    "speech_therapy": {"language_delay", "articulation", "stuttering", "voice", "autism_speech"},
    "occupational_therapy": {"sensory_integration", "fine_motor", "handwriting", "adhd_specialist"},
    "aba_therapy": {"autism_specialist", "autism", "early_intervention"},
    "special_education": {"learning_disability", "autism", "down_syndrome"},
    "behavioral_therapy": {"adhd", "anxiety", "oppositional_behavior", "adhd_specialist"},
    "physiotherapy_special_needs": {"cerebral_palsy"},
}

AGE_BUCKETS = [
    (0, 3, "toddler"),
    (3, 6, "preschool"),
    (6, 13, "school_age"),
    (13, 19, "teen"),
]


def age_bucket(age: int) -> str:
    for lo, hi, name in AGE_BUCKETS:
        if lo <= age < hi:
            return name
    return "teen"


# ---------- factor scorers ----------

def specialization_score(service_type: str, t_specs: list[str]) -> float:
    if not service_type:
        return 0.5
    if service_type in t_specs:
        return 1.0
    related = RELATED_SPECS.get(service_type, set())
    if any(s in related for s in t_specs):
        return 0.7
    return 0.3


def age_range_score(child_age: Optional[int], t_age_ranges: list[str]) -> float:
    if child_age is None:
        return 0.7
    bucket = age_bucket(child_age)
    return 1.0 if bucket in t_age_ranges else 0.4


def qualifications_score(verified: bool, level: str) -> float:
    if verified and level in ("mphil", "phd"):
        return 1.0
    if verified and level == "masters":
        return 0.85
    if verified and level == "bachelors":
        return 0.7
    return 0.5  # unverified


def distance_score(distance_km: float) -> float:
    return max(0.0, 1.0 - distance_km / 10.0)


def rating_score(rating: float) -> float:
    return max(0.0, min(1.0, (rating - 3.0) / 2.0))


def reliability_score(on_time_rate: float) -> float:
    return max(0.0, min(1.0, on_time_rate))


def price_score(price: int, budget: Optional[int]) -> float:
    if budget is None:
        return 0.7
    ratio = price / budget
    if 0.7 <= ratio <= 1.0:
        return 1.0
    if ratio < 0.7:
        return 0.85
    if 1.0 < ratio <= 1.2:
        return 0.5
    return 0.1


def cancellation_score(cancellation_rate: float) -> float:
    return max(0.0, 1.0 - cancellation_rate * 5.0)


# ---------- multipliers ----------

def verification_multiplier(verified: bool) -> float:
    return 1.15 if verified else 1.0


def gender_preference_multiplier(pref: str, t_gender: str) -> float:
    if pref == "no_preference":
        return 1.0
    if pref == t_gender:
        return 1.10
    return 0.85


# ---------- weighted total ----------

WEIGHTS = {
    "specialization": 0.20,
    "age_range": 0.15,
    "qualifications": 0.15,
    "distance": 0.10,
    "rating": 0.10,
    "reliability": 0.10,
    "price": 0.10,
    "cancellation": 0.10,
}


def compute_factor_scores(therapist: dict, intent: dict, distance_km: float, price: int) -> dict:
    return {
        "specialization": specialization_score(intent.get("service_type"), therapist["specializations"]),
        "age_range": age_range_score(intent.get("child_age"), therapist["age_ranges"]),
        "qualifications": qualifications_score(therapist["verified"], therapist["qualification_level"]),
        "distance": distance_score(distance_km),
        "rating": rating_score(therapist["rating"]),
        "reliability": reliability_score(therapist["on_time_rate"]),
        "price": price_score(price, intent.get("budget_per_session")),
        "cancellation": cancellation_score(therapist["cancellation_rate"]),
    }


def compute_overall(factor_scores: dict, therapist: dict, intent: dict) -> float:
    weighted = sum(factor_scores[k] * WEIGHTS[k] for k in WEIGHTS)
    weighted *= verification_multiplier(therapist["verified"])
    weighted *= gender_preference_multiplier(
        intent.get("gender_preference", "no_preference"),
        therapist["gender"],
    )
    return round(min(1.0, weighted), 3)
