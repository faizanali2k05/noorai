"""Services Runner — agentic pipeline for general informal-economy services.

Covers plumbers, electricians, AC technicians, carpenters, painters, home
cleaning, appliance repair, tutors, beauticians and car mechanics. Mirrors the
special-needs pipeline (Intent -> Discovery -> Ranking -> Booking -> Follow-Up),
uses the realtime LLM for natural-language understanding with a deterministic
regex fallback, and writes traces to data/traces.json so the Agent Trace screen
renders these runs too.
"""
from __future__ import annotations

import json
import random
import re
import string
import time
import uuid
from datetime import datetime, timedelta
from pathlib import Path
from typing import Tuple

from utils import llm
from utils.geo import resolve_user_location, haversine_km
from orchestrator.antigravity_runner import _make_entry, _persist_trace

DATA_DIR = Path(__file__).resolve().parent.parent / "data"
PROVIDERS_FILE = DATA_DIR / "providers.json"
SERVICE_BOOKINGS_FILE = DATA_DIR / "service_bookings.json"

# Catalog of supported categories -> human label.
CATEGORIES: dict[str, str] = {
    "ac_technician": "AC Technician",
    "plumber": "Plumber",
    "electrician": "Electrician",
    "carpenter": "Carpenter",
    "painter": "Painter",
    "home_cleaning": "Home Cleaning",
    "appliance_repair": "Appliance Repair",
    "tutor": "Home Tutor",
    "beautician": "Beautician",
    "car_mechanic": "Car Mechanic",
}

SERVICE_SYSTEM_PROMPT = """You are the Intent Agent for a Pakistani home-services marketplace.

Parents and households type requests in English, Urdu, Roman Urdu, or a mix.

Extract these fields and return ONLY valid JSON (no markdown, no preamble):
- category (one of: ac_technician, plumber, electrician, carpenter, painter, home_cleaning, appliance_repair, tutor, beautician, car_mechanic)
- city (Lahore/Karachi/Islamabad)
- area (e.g., "G-13", "Gulberg", "DHA", "F-8")
- preferred_time (morning/afternoon/evening/flexible)
- urgency (scheduled/next_day/same_day/immediate)
- budget (integer PKR, null if not mentioned)
- confidence (0.0 to 1.0)

Language hints: "kal"=tomorrow->next_day, "abhi"/"urgent"->immediate, "aaj"=today->same_day,
"subah"=morning, "shaam"=evening, "dopahar"=afternoon, "AC"/"a.c"=ac_technician,
"nalka"/"leak"=plumber, "bijli"/"wiring"=electrician, "safai"/"maid"=home_cleaning,
"tuition"/"ustaad"=tutor, "makeup"/"salon"=beautician, "gaari"=car_mechanic.
"""


# ---------- Regex fallback ----------

_CATEGORY_PATTERNS = [
    (re.compile(r"\ba\.?c\b|air ?condition", re.I), "ac_technician"),
    (re.compile(r"plumb|leak|pipe|nalka|nal\b|sanitary|drain", re.I), "plumber"),
    (re.compile(r"electric|wiring|bijli|switch|breaker|ups|fuse", re.I), "electrician"),
    (re.compile(r"carpenter|furniture|wood|lakkar|cabinet|wardrobe|door repair", re.I), "carpenter"),
    (re.compile(r"paint|whitewash|texture", re.I), "painter"),
    (re.compile(r"clean|maid|safai|deep clean|sofa shampoo", re.I), "home_cleaning"),
    (re.compile(r"fridge|refrigerator|washing machine|microwave|appliance|geyser", re.I), "appliance_repair"),
    (re.compile(r"tutor|teacher|tuition|ustaad|parhai|home tuition", re.I), "tutor"),
    (re.compile(r"beautician|salon|makeup|facial|bridal|threading|hair styl", re.I), "beautician"),
    (re.compile(r"mechanic|car repair|gaari|engine|brakes|battery", re.I), "car_mechanic"),
]

_CITY_PATTERNS = [
    (re.compile(r"lahore|lahor", re.I), "Lahore"),
    (re.compile(r"karachi|karachee", re.I), "Karachi"),
    (re.compile(r"islamabad|isb\b", re.I), "Islamabad"),
]

_AREA_PATTERN = re.compile(
    r"\b(Gulberg|DHA|Johar Town|Model Town|Clifton|Gulshan|North Nazimabad|F-\d{1,2}|G-\d{1,2}|E-\d{1,2}|I-\d{1,2})\b",
    re.I,
)

_TIME_PATTERNS = [
    (re.compile(r"subah|morning", re.I), "morning"),
    (re.compile(r"dopahar|afternoon|noon", re.I), "afternoon"),
    (re.compile(r"shaam|sham\b|evening", re.I), "evening"),
]

_URGENCY_PATTERNS = [
    (re.compile(r"abhi|right now|urgent|emergency|fauran", re.I), "immediate"),
    (re.compile(r"\baaj\b|today|same day", re.I), "same_day"),
    (re.compile(r"\bkal\b|tomorrow|next day", re.I), "next_day"),
]


def _first(text: str, patterns) -> str | None:
    for pat, val in patterns:
        if pat.search(text):
            return val
    return None


def _regex_service_intent(text: str) -> dict:
    category = _first(text, _CATEGORY_PATTERNS)
    city = _first(text, _CITY_PATTERNS)
    preferred_time = _first(text, _TIME_PATTERNS) or "flexible"
    urgency = _first(text, _URGENCY_PATTERNS) or "scheduled"

    area = None
    m = _AREA_PATTERN.search(text)
    if m:
        raw = m.group(1)
        area = raw.upper() if "-" in raw else ("DHA" if raw.lower() == "dha" else raw.title())

    budget = None
    nums = [int(n) for n in re.findall(r"\b(\d{3,6})\b", text)]
    plausible = [n for n in nums if 300 <= n <= 50000]
    if plausible:
        budget = plausible[-1]

    hits = sum(x is not None for x in (category, city, area))
    confidence = round(min(0.95, 0.45 + hits * 0.15), 2)
    return {
        "category": category,
        "city": city,
        "area": area,
        "preferred_time": preferred_time,
        "urgency": urgency,
        "budget": budget,
        "confidence": confidence,
    }


def _normalize_llm_intent(payload: dict) -> dict:
    cat = payload.get("category")
    if cat not in CATEGORIES:
        cat = None
    city = payload.get("city")
    if city not in ("Lahore", "Karachi", "Islamabad"):
        city = None
    return {
        "category": cat,
        "city": city,
        "area": payload.get("area"),
        "preferred_time": payload.get("preferred_time") or "flexible",
        "urgency": payload.get("urgency") or "scheduled",
        "budget": payload.get("budget"),
        "confidence": float(payload.get("confidence", 0.0) or 0.0),
    }


def parse_service_intent(user_message: str) -> Tuple[dict, str]:
    started = time.time()
    source = "regex"
    intent: dict | None = None

    status = llm.llm_status()
    if status.get("enabled"):
        payload = llm.chat_json(SERVICE_SYSTEM_PROMPT, f"INPUT: {user_message}\nOUTPUT:")
        if payload:
            try:
                intent = _normalize_llm_intent(payload)
                source = f"{status.get('provider')}:{status.get('model')}"
            except Exception:
                intent = None

    if intent is None or intent.get("category") is None:
        regexed = _regex_service_intent(user_message)
        if intent is None:
            intent = regexed
        else:
            # keep LLM fields but backfill a missing category from regex
            intent["category"] = intent.get("category") or regexed["category"]
            intent["city"] = intent.get("city") or regexed["city"]
            intent["area"] = intent.get("area") or regexed["area"]

    elapsed = (time.time() - started) * 1000
    reasoning = (
        f"Parsed via {source}. category={intent.get('category')}, city={intent.get('city')}, "
        f"area={intent.get('area')}, time={intent.get('preferred_time')}, "
        f"urgency={intent.get('urgency')}. Confidence={intent.get('confidence')}. ({elapsed:.0f}ms)"
    )
    return intent, reasoning


# ---------- Data ----------

def load_providers() -> list[dict]:
    return json.loads(PROVIDERS_FILE.read_text(encoding="utf-8"))


def _load_service_bookings() -> list[dict]:
    if not SERVICE_BOOKINGS_FILE.exists():
        return []
    return json.loads(SERVICE_BOOKINGS_FILE.read_text(encoding="utf-8") or "[]")


def _save_service_bookings(bookings: list[dict]) -> None:
    SERVICE_BOOKINGS_FILE.write_text(json.dumps(bookings, indent=2), encoding="utf-8")


# ---------- Ranking ----------

def _rank_providers(candidates: list[dict], intent: dict) -> list[dict]:
    user_loc = resolve_user_location(intent.get("city"), intent.get("area"))
    budget = intent.get("budget")
    ranked = []
    for p in candidates:
        if user_loc:
            dist = round(haversine_km(user_loc[0], user_loc[1], p["lat"], p["lng"]), 2)
        else:
            dist = 0.0
        # Normalised factor scores (0..1)
        distance_score = max(0.0, 1.0 - min(dist, 20.0) / 20.0)
        rating_score = (p.get("rating", 0) / 5.0)
        reliability_score = p.get("on_time_rate", 0.8)
        if budget:
            price_score = 1.0 if p["base_price"] <= budget else max(0.0, 1.0 - (p["base_price"] - budget) / budget)
        else:
            price_score = 0.7
        overall = round(
            0.40 * distance_score
            + 0.30 * rating_score
            + 0.20 * reliability_score
            + 0.10 * price_score,
            3,
        )
        reasoning = (
            f"{p['name']}: {dist}km away, {p.get('rating')}★ "
            f"({p.get('review_count')} reviews), {int(p.get('on_time_rate', 0)*100)}% on-time, "
            f"Rs {p['base_price']}/visit. Score {overall:.2f}."
        )
        ranked.append({
            "provider_id": p["id"],
            "overall_score": overall,
            "factor_scores": {
                "distance": round(distance_score, 2),
                "rating": round(rating_score, 2),
                "reliability": round(reliability_score, 2),
                "price": round(price_score, 2),
            },
            "reasoning": reasoning,
            "distance_km": dist,
            "price": p["base_price"],
            "provider": p,
        })
    ranked.sort(key=lambda r: r["overall_score"], reverse=True)
    return ranked[:5]


# ---------- Pipelines ----------

def run_find_services(user_message: str) -> dict:
    """Intent -> Discovery (category + city filter) -> Ranking. Returns ranked providers."""
    trace_id = f"tr-{uuid.uuid4().hex[:10]}"
    entries: list[dict] = []
    providers = load_providers()

    # 1. Intent
    t0 = time.time()
    intent, reasoning = parse_service_intent(user_message)
    entries.append(_make_entry(
        "Intent Agent", t0, {"user_message": user_message}, reasoning, intent
    ))

    # 2. Discovery — filter by category (and city when known)
    t0 = time.time()
    category = intent.get("category")
    city = intent.get("city")
    candidates = [p for p in providers if (not category or p["category"] == category)]
    if city:
        in_city = [p for p in candidates if p["city"] == city]
        if in_city:
            candidates = in_city
    disc_reasoning = (
        f"Filtered {len(providers)} providers to {len(candidates)} matching "
        f"category={category or 'any'}" + (f", city={city}" if city else "") + "."
    )
    entries.append(_make_entry(
        "Discovery Agent", t0,
        {"category": category, "city": city},
        disc_reasoning,
        {"candidate_count": len(candidates), "candidate_ids": [c["id"] for c in candidates]},
    ))

    # 3. Ranking
    t0 = time.time()
    ranked = _rank_providers(candidates, intent)
    entries.append(_make_entry(
        "Ranking Agent", t0,
        {"candidate_count": len(candidates), "weights": "distance/rating/reliability/price"},
        f"Ranked {len(candidates)} providers; top {len(ranked)} returned.",
        {"top_ids": [r["provider_id"] for r in ranked],
         "top_scores": [r["overall_score"] for r in ranked]},
    ))

    _persist_trace(trace_id, user_message, entries)
    return {"trace_id": trace_id, "intent": intent, "ranked": ranked}


def _gen_code(name: str) -> str:
    initials = "".join(w[0] for w in name.split()[:3]).upper() or "SV"
    return f"NA-{initials}-{''.join(random.choices(string.digits, k=4))}"


def _next_slot_dt(slot_iso: str | None, urgency: str) -> datetime:
    if slot_iso:
        try:
            return datetime.fromisoformat(slot_iso)
        except ValueError:
            pass
    base = datetime.now()
    if urgency == "immediate":
        return base + timedelta(hours=2)
    if urgency == "same_day":
        return base.replace(hour=17, minute=0, second=0, microsecond=0)
    # next_day / scheduled -> tomorrow 10:00
    return (base + timedelta(days=1)).replace(hour=10, minute=0, second=0, microsecond=0)


def run_book_service(provider_id: str, slot: str | None, intent: dict,
                     trace_id: str | None = None) -> dict:
    """Booking -> Notification -> Follow-Up for a general service provider."""
    trace_id = trace_id or f"tr-{uuid.uuid4().hex[:10]}"
    entries: list[dict] = []
    providers = load_providers()
    provider = next((p for p in providers if p["id"] == provider_id), None)
    if provider is None:
        raise ValueError(f"Unknown provider_id {provider_id}")

    # Booking
    t0 = time.time()
    dt = _next_slot_dt(slot, intent.get("urgency", "scheduled"))
    bookings = _load_service_bookings()
    today = datetime.now().strftime("%Y%m%d")
    seq = sum(1 for b in bookings if b["booking_id"].startswith(f"SV-{today}")) + 1
    booking = {
        "booking_id": f"SV-{today}-{seq:03d}",
        "provider_id": provider_id,
        "provider_name": provider["name"],
        "category": provider["category"],
        "user_id": "u001",
        "slot": dt.isoformat(timespec="seconds"),
        "date": dt.date().isoformat(),
        "time": dt.strftime("%H:%M"),
        "price": provider["base_price"],
        "confirmation_code": _gen_code(provider["name"]),
        "status": "confirmed",
        "created_at": datetime.now().astimezone().isoformat(timespec="seconds"),
        "intent_snapshot": intent,
    }
    bookings.append(booking)
    _save_service_bookings(bookings)
    entries.append(_make_entry(
        "Booking Agent", t0,
        {"provider_id": provider_id, "slot": booking["slot"]},
        f"Booked {provider['name']} on {booking['date']} at {booking['time']}. "
        f"Rs {booking['price']}. Code {booking['confirmation_code']}.",
        booking,
    ))

    # Notification (simulated WhatsApp)
    t0 = time.time()
    parent_msg = (
        f"Salam! Aap ki booking confirm ho gayi hai. {provider['name']} "
        f"{booking['date']} ko {booking['time']} baje aayenge. "
        f"Confirmation: {booking['confirmation_code']}. Rs {booking['price']}."
    )
    notifications = {
        "to_user": {"channel": "whatsapp", "language": "roman_urdu", "message": parent_msg},
        "to_provider": {
            "channel": "whatsapp",
            "language": "english",
            "message": f"New booking {booking['confirmation_code']} on {booking['date']} {booking['time']}.",
        },
    }
    entries.append(_make_entry(
        "Notification Agent", t0, {"booking_id": booking["booking_id"]},
        "Generated Roman-Urdu confirmation for the user and an English alert for the provider.",
        notifications,
    ))

    # Follow-Up (reminder 1 hour before)
    t0 = time.time()
    reminder_at = (dt - timedelta(hours=1)).isoformat(timespec="seconds")
    followup = {
        "scheduled_events": [
            {
                "type": "reminder",
                "trigger": "1_hour_before",
                "at": reminder_at,
                "message_preview": f"Reminder: {provider['name']} 1 ghante mein aa rahe hain.",
            },
            {
                "type": "completion_check",
                "trigger": "after_appointment",
                "prompt": "Service kaisi rahi? 1-5 rate karein.",
            },
        ]
    }
    entries.append(_make_entry(
        "Follow-Up Agent", t0, {"booking_id": booking["booking_id"]},
        "Scheduled a 1-hour-before reminder and a post-service feedback check.",
        followup,
    ))

    _persist_trace(trace_id, None, entries)
    return {
        "trace_id": trace_id,
        "booking": booking,
        "notifications": notifications,
        "followup": followup,
    }
