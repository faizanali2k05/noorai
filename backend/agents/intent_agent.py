"""Intent Agent — parses Urdu/Roman Urdu/English natural language into structured intent.

Uses a realtime LLM (OpenAI by default, Gemini fallback) when configured and
NOORAI_OFFLINE_MODE != "1". Falls back to a deterministic regex parser so the
demo always works even without an API key.
"""
from __future__ import annotations

import os
import re
import time
from typing import Tuple

from models.schemas import Intent
from utils import llm

SYSTEM_PROMPT = """You are the Intent Agent for NoorAI, a Pakistani special needs therapy platform.

Parents type requests in English, Urdu, Roman Urdu, or any mix - including misspellings.

Extract these fields:
- service_type (one of: speech_therapy, occupational_therapy, aba_therapy, special_education, behavioral_therapy, physiotherapy_special_needs, accessible_transport, sign_language_interpreter, home_nursing, wheelchair_repair, disability_support_worker)
- condition (one of: autism, speech_delay, adhd, learning_disability, cerebral_palsy, down_syndrome, physical_disability, hearing_impairment, visual_impairment, multiple_disabilities, other)
- child_age (integer years)
- child_gender (male/female/not_specified)
- city (Lahore/Karachi/Islamabad)
- area (e.g., "Gulberg", "DHA", "F-8")
- frequency (one_time/weekly/biweekly/thrice_weekly)
- preferred_time (morning/afternoon/evening/flexible)
- budget_per_session (integer PKR, null if not mentioned)
- urgency (scheduled/next_day/same_day/immediate)
- gender_preference (female/male/no_preference)
- confidence (0.0 to 1.0)

Language hints:
- "kal" = tomorrow -> next_day
- "abhi" / "urgently" / "emergency" -> immediate
- "subah" = morning, "shaam" = evening, "dopahar" = afternoon
- "hafte mein 2 baar" = biweekly
- "beti" = daughter (female child), "beta" = son (male child)
- "femal" / "fmle" -> likely "female"

If confidence < 0.60, set needs_clarification=true and provide a clarification_question in Roman Urdu.
If a critical field is missing (city, condition, child_age), list it in missing_fields.

Return ONLY valid JSON. No markdown, no preamble.
"""


# ---------- Regex fallback ----------

SERVICE_PATTERNS = [
    (re.compile(r"\bspeech\b|\bzubaan\b|\bbolne\b|slp|s\.?l\.?p\.?", re.I), "speech_therapy"),
    (re.compile(r"occupational|\bot\b|sensory|handwriting|fine motor", re.I), "occupational_therapy"),
    (re.compile(r"\baba\b|behavior analysis", re.I), "aba_therapy"),
    (re.compile(r"special education|special ed|resource teacher|learning", re.I), "special_education"),
    (re.compile(r"behavioral|behaviour|cbt|anxiety|conduct", re.I), "behavioral_therapy"),
    (re.compile(r"physio|physical therap|cerebral palsy|cp\b", re.I), "physiotherapy_special_needs"),
    (re.compile(r"transport|van|wheelchair accessible|ride|pickup|pick and drop|pick drop", re.I), "accessible_transport"),
    (re.compile(r"sign language|interpreter|isharon ki zaban|deaf communication", re.I), "sign_language_interpreter"),
    (re.compile(r"nurse|home nursing|caregiver|medical care|attendant", re.I), "home_nursing"),
    (re.compile(r"wheelchair repair|wheel chair mechanic|repair|fix wheelchair", re.I), "wheelchair_repair"),
    (re.compile(r"support worker|care worker|helper|disability support|sahara", re.I), "disability_support_worker"),
]

CONDITION_PATTERNS = [
    (re.compile(r"autism|asd\b", re.I), "autism"),
    (re.compile(r"speech delay|late talker|nahi bolta|nahi bolti", re.I), "speech_delay"),
    (re.compile(r"adhd|hyperactiv|attention", re.I), "adhd"),
    (re.compile(r"learning disabilit|dyslex|dyscalc", re.I), "learning_disability"),
    (re.compile(r"cerebral palsy|\bcp\b", re.I), "cerebral_palsy"),
    (re.compile(r"down syndrome|down's", re.I), "down_syndrome"),
    (re.compile(r"physical disabilit|mazoor|wheelchair bound|paralyzed|polio", re.I), "physical_disability"),
    (re.compile(r"hearing impair|deaf|sun nahi sakta|behra", re.I), "hearing_impairment"),
    (re.compile(r"visual impair|blind|dekh nahi sakta|andha", re.I), "visual_impairment"),
    (re.compile(r"multiple disabilit|severe disability", re.I), "multiple_disabilities"),
]

CITY_PATTERNS = [
    (re.compile(r"lahore", re.I), "Lahore"),
    (re.compile(r"karachi", re.I), "Karachi"),
    (re.compile(r"islamabad|isb\b", re.I), "Islamabad"),
]

AREA_PATTERNS = [
    re.compile(r"\b(Gulberg|DHA|Johar Town|Model Town|Clifton|Gulshan|North Nazimabad|F-\d{1,2}|G-\d{1,2}|E-\d{1,2}|I-\d{1,2})\b", re.I),
]

FREQUENCY_PATTERNS = [
    (re.compile(r"3 baar|teen baar|thrice|three times", re.I), "thrice_weekly"),
    (re.compile(r"2 baar|do baar|biweekly|hafte mein 2|twice", re.I), "biweekly"),
    (re.compile(r"weekly|hafte mein|once a week", re.I), "weekly"),
]

GENDER_CHILD_PATTERNS = [
    (re.compile(r"\bbeti\b|\bdaughter\b|\bgirl\b|\blarki\b", re.I), "female"),
    (re.compile(r"\bbeta\b|\bson\b|\bboy\b|\blarka\b", re.I), "male"),
]

GENDER_PREFERENCE_PATTERNS = [
    (re.compile(r"femal[ae]?|fmle|female therapist|lady|aurat", re.I), "female"),
    (re.compile(r"\bmale\b|male therapist|aadmi", re.I), "male"),
]

URGENCY_PATTERNS = [
    (re.compile(r"abhi|right now|urgently|urgent|emergency|fauran", re.I), "immediate"),
    (re.compile(r"\baaj\b|today|same day", re.I), "same_day"),
    (re.compile(r"\bkal\b|tomorrow|next day", re.I), "next_day"),
]

TIME_PATTERNS = [
    (re.compile(r"subah|morning", re.I), "morning"),
    (re.compile(r"dopahar|afternoon|noon", re.I), "afternoon"),
    (re.compile(r"shaam|evening|sham\b", re.I), "evening"),
]

AGE_PATTERN = re.compile(r"(\d{1,2})\s*(saal|years?|yrs?|year[- ]?old|sal)", re.I)
BUDGET_PATTERN = re.compile(r"(?:rs|pkr|budget|tak|maximum|under)?\s*(\d{3,5})\s*(?:rupees|rs|pkr|budget|tak|/-)?", re.I)


def _first_match(text: str, patterns) -> str | None:
    for pat, value in patterns:
        if pat.search(text):
            return value
    return None


def _regex_parse(text: str) -> Intent:
    service = _first_match(text, SERVICE_PATTERNS)
    condition = _first_match(text, CONDITION_PATTERNS)
    city = _first_match(text, CITY_PATTERNS)
    frequency = _first_match(text, FREQUENCY_PATTERNS) or "one_time"
    child_gender = _first_match(text, GENDER_CHILD_PATTERNS) or "not_specified"
    gender_pref = _first_match(text, GENDER_PREFERENCE_PATTERNS) or "no_preference"
    urgency = _first_match(text, URGENCY_PATTERNS) or "scheduled"
    preferred_time = _first_match(text, TIME_PATTERNS) or "flexible"

    area = None
    for pat in AREA_PATTERNS:
        m = pat.search(text)
        if m:
            raw = m.group(1)
            # Normalize "f-8" -> "F-8", "dha" -> "DHA"
            if "-" in raw:
                area = raw.upper()
            elif raw.lower() in ("dha",):
                area = "DHA"
            else:
                area = raw.title()
            break

    age = None
    m = AGE_PATTERN.search(text)
    if m:
        age = int(m.group(1))

    budget = None
    # Pick the largest standalone number 1000-15000 that looks like a budget
    nums = [int(n) for n in re.findall(r"\b(\d{3,5})\b", text)]
    plausible = [n for n in nums if 1000 <= n <= 15000]
    if plausible:
        budget = plausible[-1]

    # Confidence heuristic
    field_hits = sum(x is not None for x in (service, condition, city, area, age))
    confidence = min(0.95, 0.40 + field_hits * 0.12)

    missing = []
    if not city: missing.append("city")
    if not condition: missing.append("condition")
    if age is None: missing.append("child_age")
    if not service: missing.append("service_type")

    needs_clar = confidence < 0.60

    clarification_question = None
    if needs_clar:
        clarification_question = (
            "Bachay ki age, condition, sheher, aur kis tarah ka therapist chahiye yeh bata den."
        )

    return Intent(
        service_type=service,
        condition=condition,
        child_age=age,
        child_gender=child_gender,
        city=city,
        area=area,
        frequency=frequency,
        preferred_time=preferred_time,
        budget_per_session=budget,
        urgency=urgency,
        gender_preference=gender_pref,
        confidence=round(confidence, 2),
        needs_clarification=needs_clar,
        missing_fields=missing,
        clarification_question=clarification_question,
    )


# ---------- Gemini call ----------

def _llm_parse(text: str) -> Intent | None:
    """Parse intent via the configured realtime LLM, or None to fall back."""
    payload = llm.chat_json(SYSTEM_PROMPT, f"INPUT: {text}\nOUTPUT:")
    if not payload:
        return None
    try:
        return Intent(**{k: v for k, v in payload.items() if k in Intent.model_fields})
    except Exception as exc:
        print(f"[intent_agent] LLM returned unusable JSON, using regex fallback: {exc}")
        return None


# ---------- Public ----------

def run(user_message: str) -> Tuple[Intent, str]:
    """Returns (Intent, reasoning_string). Reasoning string used by orchestrator for trace."""
    started = time.time()

    intent: Intent | None = None
    source = "regex"
    status = llm.llm_status()
    if status.get("enabled"):
        intent = _llm_parse(user_message)
        if intent is not None:
            source = f"{status.get('provider')}:{status.get('model')}"

    if intent is None:
        intent = _regex_parse(user_message)

    elapsed = (time.time() - started) * 1000

    reasoning = (
        f"Parsed via {source}. Extracted service={intent.service_type}, "
        f"condition={intent.condition}, city={intent.city}, area={intent.area}, "
        f"age={intent.child_age}, budget={intent.budget_per_session}. "
        f"Confidence={intent.confidence}. ({elapsed:.0f}ms)"
    )
    return intent, reasoning
