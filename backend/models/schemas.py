from __future__ import annotations

from typing import List, Literal, Optional
from pydantic import BaseModel, Field


# ---------- Intent ----------

ServiceType = Literal[
    "speech_therapy",
    "occupational_therapy",
    "aba_therapy",
    "special_education",
    "behavioral_therapy",
    "physiotherapy_special_needs",
    "accessible_transport",
    "sign_language_interpreter",
    "home_nursing",
    "wheelchair_repair",
    "disability_support_worker",
]

Condition = Literal[
    "autism",
    "speech_delay",
    "adhd",
    "learning_disability",
    "cerebral_palsy",
    "down_syndrome",
    "physical_disability",
    "hearing_impairment",
    "visual_impairment",
    "multiple_disabilities",
    "other",
]

City = Literal["Lahore", "Karachi", "Islamabad"]
Gender = Literal["male", "female", "not_specified"]
GenderPreference = Literal["female", "male", "no_preference"]
Frequency = Literal["one_time", "weekly", "biweekly", "thrice_weekly"]
PreferredTime = Literal["morning", "afternoon", "evening", "flexible"]
Urgency = Literal["scheduled", "next_day", "same_day", "immediate"]


class Intent(BaseModel):
    service_type: Optional[ServiceType] = None
    condition: Optional[Condition] = None
    child_age: Optional[int] = None
    child_gender: Gender = "not_specified"
    city: Optional[City] = None
    area: Optional[str] = None
    frequency: Frequency = "one_time"
    preferred_time: PreferredTime = "flexible"
    budget_per_session: Optional[int] = None
    urgency: Urgency = "scheduled"
    gender_preference: GenderPreference = "no_preference"
    confidence: float = 0.0
    needs_clarification: bool = False
    missing_fields: List[str] = Field(default_factory=list)
    clarification_question: Optional[str] = None


# ---------- Therapist ----------

class Therapist(BaseModel):
    id: str
    name: str
    gender: Literal["male", "female"]
    specializations: List[str]
    qualifications: List[str]
    qualification_level: Literal["bachelors", "masters", "mphil", "phd"]
    verified: bool
    city: str
    area: str
    lat: float
    lng: float
    rating: float
    review_count: int
    last_review_days_ago: int
    on_time_rate: float
    cancellation_rate: float
    base_price: int
    age_ranges: List[str]
    experience_years: int
    available_slots: List[str]
    bio: str
    languages: List[str]


# ---------- Ranking ----------

class FactorScores(BaseModel):
    specialization: float
    age_range: float
    qualifications: float
    distance: float
    rating: float
    reliability: float
    price: float
    cancellation: float


class RankedTherapist(BaseModel):
    therapist_id: str
    overall_score: float
    factor_scores: FactorScores
    reasoning: str
    distance_km: float
    price: int


# ---------- Pricing ----------

class PriceBreakdown(BaseModel):
    base_rate: int
    distance_surcharge: int
    urgency_multiplier: float
    complexity_multiplier: float
    subtotal: int
    loyalty_discount: int
    final_price: int
    breakdown_explanation: str


# ---------- Booking ----------

class Session(BaseModel):
    date: str
    time: str
    duration_min: int = 45
    status: Literal["confirmed", "completed", "cancelled"] = "confirmed"


class Booking(BaseModel):
    booking_id: str
    therapist_id: str
    user_id: str = "u001"
    sessions: List[Session]
    total_price: int
    confirmation_code: str
    status: Literal["confirmed", "therapist_cancelled", "user_cancelled", "completed", "rebooked"] = "confirmed"
    created_at: str
    intent_snapshot: Optional[dict] = None


# ---------- Notification ----------

class NotificationMessage(BaseModel):
    channel: Literal["whatsapp", "sms"]
    language: Literal["roman_urdu", "urdu", "english"]
    message: str


class NotificationPair(BaseModel):
    to_parent: NotificationMessage
    to_therapist: NotificationMessage


# ---------- Follow-up ----------

class FollowupEvent(BaseModel):
    type: str
    trigger: str
    target_session: Optional[int] = None
    message_preview: Optional[str] = None
    prompt: Optional[str] = None
    summary: Optional[str] = None
    status: Literal["scheduled", "sent", "done"] = "scheduled"


class FollowupPlan(BaseModel):
    booking_id: str
    scheduled_events: List[FollowupEvent]


# ---------- Dispute ----------

class DisputeResolution(BaseModel):
    action: Literal["auto_rebook_proposed", "reschedule_required", "refund_initiated", "complaint_logged"]
    booking_id: str
    user_message: str
    alternative_therapist_id: Optional[str] = None
    alternatives: List[str] = Field(default_factory=list)
    compensation: Optional[str] = None


# ---------- API request/response ----------

class FindRequest(BaseModel):
    user_message: str
    user_lat: Optional[float] = None
    user_lng: Optional[float] = None


class FindResponse(BaseModel):
    trace_id: str
    intent: Intent
    ranked: List[RankedTherapist]
    pricing: dict  # {therapist_id: PriceBreakdown}


class BookingRequest(BaseModel):
    therapist_id: str
    slot: str  # ISO datetime
    intent: Intent
    sessions_count: int = 1
    trace_id: Optional[str] = None


class BookingResponse(BaseModel):
    trace_id: str
    booking: Booking
    notifications: NotificationPair
    followup: FollowupPlan


class DisputeRequest(BaseModel):
    booking_id: str
    reason: Literal["therapist_cancelled", "no_show", "price_dispute", "complaint", "user_cancel"]


class DisputeResponse(BaseModel):
    trace_id: str
    resolution: DisputeResolution
    alternative: Optional[RankedTherapist] = None


# ---------- Trace ----------

class TraceEntry(BaseModel):
    agent: str
    started_at: str
    duration_ms: int
    input_summary: str
    reasoning: str
    output_summary: str
    output_payload: dict


class TraceLog(BaseModel):
    trace_id: str
    created_at: str
    user_message: Optional[str] = None
    entries: List[TraceEntry]
