# NoorAI — AI Coding Spec

> **Project:** NoorAI — Pakistan's First Agentic Special Needs Therapy Marketplace  
> **Tagline:** *Every child is a light. NoorAI helps families find the right guide.*  
> **Hackathon:** Google Antigravity Hackathon — Challenge 2 (AI Service Orchestrator for Informal Economy)  
> **Submission Deadline:** May 20, 2026  
> **Prize:** 2.5M PKR  
> **Name Rationale:** *Noor* (نور) = light in Urdu/Arabic. Pakistani families with special-needs children widely use this term of endearment. Judges will feel it. No plumber app can compete emotionally.

---

## 🎯 How To Use This Document

This is a **build spec for AI coding tools** (Cursor, Claude Code, Antigravity, GitHub Copilot). Feed entire file as context. Each section is self-contained and code-ready.

**Build order:**
1. Read sections 1–4 (context)
2. Build mock data (section 7)
3. Build agents one by one (section 6) — start with Intent Agent
4. Build backend API (section 9)
5. Build Flutter app screens (section 8) — start with Home + Result
6. Wire stress test + baseline (sections 10, 11)
7. Polish demo screens, record video

---

## 1. One-Line Pitch

> NoorAI is an agentic AI system that connects Pakistani families of special-needs children to verified therapists through natural language in Urdu/Roman Urdu/English — using an 8-factor intelligent matching engine, dynamic pricing, and fully automated follow-up, all orchestrated by Google Antigravity.

**Why "NoorAI" wins the name game:**  
Every other team will name their project something like "ServiceMate" or "QuickBook". NoorAI is the only name in this hackathon that the judge will still remember 3 days later. *Noor* (نور) is light in Urdu. Pakistani families with special-needs children call them their Noor. The name is the story. Use it everywhere.

---

## 2. Why This Domain (Not Plumber/AC) — The Strategic Bet

- **90%+ of teams will build the default plumber/AC scenario** verbatim from the brief. Judges will have seen it 8 times before your demo.
- Special needs therapy is **emotionally resonant, under-served, and uniquely Pakistani** — 350,000+ children are on the autism spectrum in Pakistan alone; most families still find therapists through Facebook posts.
- The domain **demands richer agentic reasoning** (therapy type, child age, qualifications, gender preference, session frequency, urgency) — your 8-factor ranking agent will look trivially more complex than a plumber distance-sort. This directly satisfies the 20% Matching Quality criterion judges are watching for.
- **Recurring booking = stronger follow-up demonstration.** A plumber is one-time. A speech therapist is biweekly for months. Your Follow-Up Agent has 5 meaningful events to show.
- **Emotional resonance breaks ties.** When scores are close, judges pick the project they remember. They remember "helped a child with autism" over "booked an AC guy".
- **Dispute resolution is more complex:** Therapist cancels on a special-needs child the day before? That's a genuine crisis with emotional stakes. Your Dispute Agent resolving it in 4 seconds is unforgettable in a demo.

---

## 2b. 🏆 Judge Score Map — How NoorAI Wins Every Criterion

> **This section is non-negotiable. Every feature in this spec exists because of one of these 6 lines.**

| Criterion | Weight | What Judges Verify | NoorAI's Answer | Where to Show It |
|-----------|--------|--------------------|-----------------|------------------|
| **Google Antigravity** | 25% | Is Antigravity actually orchestrating core logic, or bolted on? | All 7 agents run inside Antigravity. Exported Workplan + Tasks Plan submitted as artifact. Agent Artifacts captured per session. | Screen 6 (live trace) + Antigravity dashboard screenshot in README |
| **Agentic Reasoning & Workflow** | 20% | Multi-step reasoning? Autonomous recovery? Traceable decisions? | 7 chained agents with explicit handoffs. Dispute Agent auto-recovers from cancellation without human input. Reasoning visible per agent. | Screen 6 timeline + Stress Test 2 live demo |
| **Matching Quality & Decision Logic** | 20% | Is matching meaningful? Is the reasoning explained? | 8-factor weighted scoring (not distance-only). Factor scores shown as bars. Natural language reasoning per match. Baseline comparison exposes the gap. | Screen 2 (score bars) + Screen 8 (baseline) |
| **Action Simulation & Execution** | 15% | Is booking realistically simulated? Is system state visibly changed? | bookings.json written. Confirmation code generated. WhatsApp message mocked. Before/after state shown. | Screen 4 + Screen 7 (dispute rebook) |
| **Technical Implementation** | 10% | Clean architecture? Edge cases handled? API integration? | 7 modular agents, Pydantic schemas, Haversine geo, optimistic slot locking, multilingual NLP, 5 stress test scenarios | Architecture diagram in README + code structure |
| **Innovation & UX** | 10% | Creative? Compelling? Easy to demo? | Only special-needs platform. Roman Urdu NLP. "AI vs Traditional" screen. Animated agent trace. Culturally resonant design. | Demo video hook + Screen 1 design |

**Golden rule:** Every screen, every agent, every JSON field maps to a row in this table. If it doesn't → cut it.

---

## 3. Challenge 2 Requirements (MUST HIT ALL)

| # | Requirement | Status | Implementation |
|---|-------------|--------|----------------|
| 1 | Mobile APK | MUST | Flutter release build |
| 2 | Google Antigravity as core | MUST | All 7 agents orchestrated via Antigravity |
| 3 | **Antigravity Workplan + Tasks Plan** | MUST ⚠️ (explicit in challenge doc, most teams miss this) | Exported from Antigravity per request; submitted as screenshots + artifact in README |
| 4 | Multilingual (Urdu/Roman Urdu/English/mixed) | MUST | Intent Agent + Gemini |
| 5 | 6+ matching factors | MUST | **8 factors implemented** (section 6.3) — exceeds requirement deliberately |
| 6 | Dynamic pricing with breakdown | MUST | Pricing Agent (section 6.4) |
| 7 | End-to-end booking simulation | MUST | Booking Agent + Screen 4 |
| 8 | Follow-up automation | MUST | Follow-Up Agent + Screen 5 |
| 9 | Dispute & cancellation handling | MUST | Dispute Agent + Screen 7 |
| 10 | Agent trace logs | MUST | Screen 6 (live animated) + Antigravity Artifacts |
| 11 | Baseline comparison | MUST | Screen 8 — free points, don't skip |
| 12 | At least one stress test | MUST | 5 implemented; Scenario 2 demoed live |
| 13 | Demo video (3–5 min) | MUST | Scripted in section 13 |
| 14 | README documentation | MUST | Architecture + explicit Antigravity usage walkthrough |
| 15 | No real personal data | MUST | All mock |

> ⚠️ **Item 3 is the most-missed requirement.** The challenge doc explicitly lists "Workplan" and "Tasks Plan" as deliverables from Antigravity. Export these from Antigravity and embed screenshots in the README. Most teams won't notice. This is easy points.

---

## 4. Tech Stack (Lock This — Don't Change)

```yaml
Mobile App:        Flutter (Dart) — Material 3
Backend API:       Python 3.11 + FastAPI
Agent Platform:    Google Antigravity (MANDATORY — 25% of score)
LLM:               Gemini 2.0 Flash (via Antigravity)
Data Store:        JSON flat files (no DB needed)
State Management:  Flutter Provider package
HTTP Client:       Dart http package
Hosting:           Local for demo (no deploy time)
```

**Reasoning:**
- Flutter → single codebase, easy APK build
- Python → native Antigravity + Gemini SDK compatibility
- JSON files → faster than spinning up a DB for 3 days
- Local hosting → no DevOps time wasted; demo runs locally

---

## 5. Project Structure (Create This Exactly)

```
noorai/
├── backend/
│   ├── main.py                    # FastAPI entry point
│   ├── agents/
│   │   ├── __init__.py
│   │   ├── intent_agent.py
│   │   ├── discovery_agent.py
│   │   ├── ranking_agent.py
│   │   ├── pricing_agent.py
│   │   ├── booking_agent.py
│   │   ├── notification_agent.py
│   │   ├── followup_agent.py
│   │   └── dispute_agent.py
│   ├── orchestrator/
│   │   └── antigravity_runner.py  # Antigravity orchestration — THE CORE
│   ├── data/
│   │   ├── therapists.json        # 30 mock therapists
│   │   ├── bookings.json          # Mock bookings store
│   │   └── traces.json            # Agent trace logs
│   ├── models/
│   │   └── schemas.py             # Pydantic models
│   ├── utils/
│   │   ├── geo.py                 # Haversine distance
│   │   └── scoring.py             # 8-factor scoring
│   ├── requirements.txt
│   └── .env                       # GEMINI_API_KEY
│
├── mobile/
│   └── lib/
│       ├── main.dart
│       ├── screens/
│       │   ├── home_screen.dart
│       │   ├── provider_list_screen.dart
│       │   ├── provider_detail_screen.dart
│       │   ├── booking_confirmation_screen.dart
│       │   ├── followup_screen.dart
│       │   ├── agent_trace_screen.dart      # THE HERO SCREEN
│       │   ├── dispute_screen.dart
│       │   └── baseline_compare_screen.dart
│       ├── services/
│       │   └── api_service.dart
│       ├── models/
│       │   ├── therapist.dart
│       │   ├── booking.dart
│       │   └── trace_entry.dart
│       └── widgets/
│           ├── trace_card.dart
│           ├── score_bar.dart
│           └── price_breakdown.dart
│
└── docs/
    ├── README.md
    ├── ARCHITECTURE.md
    ├── ANTIGRAVITY_WALKTHROUGH.md   # NEW — show workplan + tasks plan screenshots
    └── DEMO_SCRIPT.md
```

---

## 6. The 7 Agents (Complete Specs)

### 6.1 Intent Agent

**Purpose:** Parse natural language (Urdu/Roman Urdu/English/mixed) into structured intent.

**Input:** `{ "user_message": string }`

**Output Schema:**
```json
{
  "service_type": "speech_therapy | occupational_therapy | aba_therapy | special_education | behavioral_therapy | physiotherapy_special_needs",
  "condition": "autism | speech_delay | adhd | learning_disability | cerebral_palsy | down_syndrome | other",
  "child_age": 5,
  "child_gender": "male | female | not_specified",
  "city": "Lahore | Karachi | Islamabad",
  "area": "Gulberg",
  "frequency": "one_time | weekly | biweekly | thrice_weekly",
  "preferred_time": "morning | afternoon | evening | flexible",
  "budget_per_session": 3000,
  "urgency": "scheduled | next_day | same_day | immediate",
  "gender_preference": "female | male | no_preference",
  "confidence": 0.94,
  "needs_clarification": false,
  "missing_fields": [],
  "clarification_question": null
}
```

**System Prompt (USE THIS VERBATIM IN ANTIGRAVITY):**
```
You are the Intent Agent for TheraConnect, a Pakistani special needs therapy platform.

Parents type requests in English, Urdu, Roman Urdu, or any mix — including misspellings.

Extract these fields:
- service_type (one of: speech_therapy, occupational_therapy, aba_therapy, special_education, behavioral_therapy, physiotherapy_special_needs)
- condition (one of: autism, speech_delay, adhd, learning_disability, cerebral_palsy, down_syndrome, other)
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
- "kal" = tomorrow → next_day
- "abhi" / "urgently" / "emergency" → immediate
- "subah" = morning, "shaam" = evening, "dopahar" = afternoon
- "hafte mein 2 baar" = biweekly
- "beti" = daughter (female child), "beta" = son (male child)
- "femal" / "fmle" → likely "female"

If confidence < 0.60, set needs_clarification=true and provide a clarification_question in Roman Urdu.
If a critical field is missing (city, condition, child_age), list it in missing_fields.

Examples:

INPUT: "Mere bete ko speech delay hai 5 saal ka hai Gulberg Lahore mein hafte mein 2 baar 3000 budget"
OUTPUT:
{
  "service_type": "speech_therapy",
  "condition": "speech_delay",
  "child_age": 5,
  "child_gender": "male",
  "city": "Lahore",
  "area": "Gulberg",
  "frequency": "biweekly",
  "preferred_time": "flexible",
  "budget_per_session": 3000,
  "urgency": "scheduled",
  "gender_preference": "no_preference",
  "confidence": 0.94,
  "needs_clarification": false,
  "missing_fields": [],
  "clarification_question": null
}

INPUT: "beti k liye femal speech thrpst chye 4 saal F-8 Islamabad"
OUTPUT:
{
  "service_type": "speech_therapy",
  "condition": "other",
  "child_age": 4,
  "child_gender": "female",
  "city": "Islamabad",
  "area": "F-8",
  "frequency": "one_time",
  "preferred_time": "flexible",
  "budget_per_session": null,
  "urgency": "scheduled",
  "gender_preference": "female",
  "confidence": 0.82,
  "needs_clarification": true,
  "missing_fields": ["condition", "frequency"],
  "clarification_question": "Aap ki beti ki kya condition hai (autism, speech delay, etc.)? Aur hafte mein kitni baar therapy chahiye?"
}

INPUT: "therapist chahiye"
OUTPUT:
{
  "service_type": null,
  "condition": null,
  "child_age": null,
  "city": null,
  "area": null,
  "confidence": 0.21,
  "needs_clarification": true,
  "missing_fields": ["service_type", "condition", "child_age", "city"],
  "clarification_question": "Bachay ki age, condition, sheher, aur kis tarah ka therapist chahiye yeh bata den."
}

Return ONLY valid JSON. No markdown, no preamble.
```

---

### 6.2 Discovery Agent

**Purpose:** Filter therapists from mock database matching intent.

**Logic:**
```python
def discover_therapists(intent, all_therapists):
    candidates = []
    for t in all_therapists:
        # Hard filters
        if intent.city != t.city:
            continue
        if intent.service_type not in t.specializations:
            continue
        # Age range check
        if not age_in_range(intent.child_age, t.age_ranges):
            continue
        
        # Distance check (within 5km initially)
        dist = haversine(intent.location, t.location)
        if dist <= 5.0:
            candidates.append({**t, "distance_km": dist})
    
    # If no results within 5km, expand
    if not candidates:
        for t in all_therapists:
            if intent.city == t.city and intent.service_type in t.specializations:
                dist = haversine(intent.location, t.location)
                if dist <= 15.0:
                    candidates.append({**t, "distance_km": dist})
    
    return candidates
```

---

### 6.3 Ranking Agent — THE 8 FACTORS

**Scoring Formula:**
```
final_score = Σ(factor_score × factor_weight) 
              × verification_multiplier 
              × gender_preference_multiplier
```

**8 Factors:**

| # | Factor | Weight | Score Calculation |
|---|--------|--------|-------------------|
| 1 | Specialization Match | 0.20 | 1.0 if exact spec match; 0.7 if related; 0.3 if generic |
| 2 | Age Range Fit | 0.15 | 1.0 if child_age in t.age_ranges; else 0.4 |
| 3 | Qualifications | 0.15 | 1.0 verified+M.Phil/PhD; 0.85 verified+Masters; 0.7 verified+Bachelors; 0.5 unverified |
| 4 | Distance | 0.10 | max(0, 1 - distance_km / 10) |
| 5 | Rating | 0.10 | (rating - 3.0) / 2.0, clamped [0,1] |
| 6 | Reliability | 0.10 | on_time_rate (0 to 1) |
| 7 | Price vs Budget | 0.10 | See below |
| 8 | Cancellation Rate | 0.10 | max(0, 1 - cancellation_rate × 5) |

**Price vs Budget logic:**
```python
def price_score(price, budget):
    if budget is None:
        return 0.7  # Neutral
    ratio = price / budget
    if 0.7 <= ratio <= 1.0:
        return 1.0  # Sweet spot
    elif ratio < 0.7:
        return 0.85  # Below budget = good but suspicious (too cheap)
    elif 1.0 < ratio <= 1.2:
        return 0.5  # Slightly over
    else:
        return 0.1  # Way over
```

**Multipliers:**
- `verification_multiplier`: 1.15 if verified, 1.0 otherwise
- `gender_preference_multiplier`: 1.10 if therapist matches preference; 0.85 if requested female but male available; 1.0 if no preference

**Output Schema:**
```json
{
  "ranked_therapists": [
    {
      "therapist_id": "t007",
      "overall_score": 0.92,
      "factor_scores": {
        "specialization": 1.0,
        "age_range": 1.0,
        "qualifications": 1.0,
        "distance": 0.77,
        "rating": 0.90,
        "reliability": 0.94,
        "price": 0.93,
        "cancellation": 0.85
      },
      "reasoning": "Top match: M.Phil pediatric speech specialist, 2.3km away, 4.8★ with 64 reviews, 94% on-time rate, fits budget."
    }
  ]
}
```

---

### 6.4 Pricing Agent

**Formula:**
```
final_price = (base_rate + distance_surcharge) 
              × urgency_multiplier 
              × complexity_multiplier 
              − loyalty_discount
```

| Component | Value |
|-----------|-------|
| Base Rate | t.base_price (Rs 2,000–5,000) |
| Distance Surcharge | Rs 100/km for distance > 3km |
| Urgency Multiplier | scheduled=1.0, next_day=1.15, same_day=1.3, immediate=1.5 |
| Complexity Multiplier | autism+adhd combo=1.4, single severe=1.2, basic=1.0 |
| Loyalty Discount | 5 sessions=5%, 15=10%, 30=15% |

**Output Schema:**
```json
{
  "base_rate": 2800,
  "distance_surcharge": 0,
  "urgency_multiplier": 1.0,
  "complexity_multiplier": 1.2,
  "subtotal": 3360,
  "loyalty_discount": 0,
  "final_price": 3360,
  "breakdown_explanation": "Base Rs 2,800 + 0 distance × 1.0 urgency × 1.2 complexity − Rs 0 loyalty = Rs 3,360"
}
```

---

### 6.5 Booking Agent

**Purpose:** Simulate booking. Write to `data/bookings.json`.

**Output Schema:**
```json
{
  "booking_id": "BK-20260518-001",
  "therapist_id": "t007",
  "user_id": "u001",
  "sessions": [
    {"date": "2026-05-19", "time": "16:00", "duration_min": 45, "status": "confirmed"},
    {"date": "2026-05-22", "time": "16:00", "duration_min": 45, "status": "confirmed"}
  ],
  "total_price": 6720,
  "confirmation_code": "TC-AYK-4291",
  "status": "confirmed",
  "created_at": "2026-05-18T11:30:00+05:00"
}
```

**Optimistic locking:** Before confirming, re-check slot availability. If taken, return conflict + suggest next slot.

---

### 6.6 Notification Agent

**Purpose:** Generate mock WhatsApp/SMS messages (no real send).

**Output:**
```json
{
  "to_parent": {
    "channel": "whatsapp",
    "language": "roman_urdu",
    "message": "Salam Sadia! Aap ka booking confirm ho gaya hai. Dr. Ayesha Khan (Speech Therapist) kal 19 May, 4:00 PM ko aap ke ghar aayegi. Confirmation code: TC-AYK-4291. Total: Rs 6,720 (2 sessions). Cancel/reschedule: app khol kar 'My Bookings' mein jaayen."
  },
  "to_therapist": {
    "channel": "whatsapp",
    "language": "english",
    "message": "Hi Dr. Ayesha, you have a new confirmed booking. Patient: Hamza (age 5, speech delay). Address: Gulberg III, Lahore. First session: May 19, 4:00 PM. Total sessions: 2 (Mon/Thu). Family contact will be shared 1 hour before."
  }
}
```

---

### 6.7 Follow-Up Agent

**Purpose:** Schedule reminders, post-session feedback, progress check-ins.

**Output:**
```json
{
  "scheduled_events": [
    {"type": "session_reminder", "trigger": "1_hour_before", "target_session": 1, "message_preview": "Dr. Ayesha 1 ghante mein aane wali hain..."},
    {"type": "post_session_feedback", "trigger": "30_min_after", "target_session": 1, "prompt": "Session kaisi rahi? 1-5 rate karen."},
    {"type": "session_reminder", "trigger": "1_hour_before", "target_session": 2, "message_preview": "..."},
    {"type": "progress_digest", "trigger": "after_4_sessions", "summary": "Monthly progress check"},
    {"type": "renewal_nudge", "trigger": "after_session_8", "message_preview": "Aap ki therapy package complete ho rahi hai. Continue karein?"}
  ]
}
```

---

### 6.8 Dispute Agent

**Triggers:** therapist cancels, no-show, price dispute, complaint

**For cancellation (THE DEMO STRESS TEST):**
```python
def handle_cancellation(booking, reason):
    # Re-run discovery + ranking, excluding cancelled therapist
    new_candidates = discover_therapists(original_intent, exclude=[booking.therapist_id])
    ranked = rank_therapists(new_candidates, original_intent)
    top_alt = ranked[0]
    
    # Try to match exact same slot
    if top_alt.has_slot(booking.sessions[0].datetime):
        return {
            "action": "auto_rebook_proposed",
            "alternative": top_alt,
            "user_message": f"Dr. {booking.therapist.name} had to cancel. We found Dr. {top_alt.name} ({top_alt.rating}★, {top_alt.distance_km}km) for the same slot. Tap to confirm.",
            "compensation": "10% discount on next session"
        }
    else:
        return {
            "action": "reschedule_required",
            "alternatives": ranked[:3]
        }
```

---

## 7. Mock Data — 30 Therapists

**File:** `backend/data/therapists.json`

**Distribution:**
- Lahore: 12 (Gulberg, DHA, Johar Town, Model Town)
- Karachi: 10 (Clifton, DHA, Gulshan, North Nazimabad)
- Islamabad: 8 (F-8, F-10, F-11, G-9, G-10, G-13)

**Specialization spread:**
- Speech Therapy: 8
- Occupational Therapy: 6
- ABA Therapy: 5
- Special Education: 5
- Behavioral Therapy: 4
- Physiotherapy (Special Needs): 2

**Each therapist record:**
```json
{
  "id": "t001",
  "name": "Dr. Ayesha Khan",
  "gender": "female",
  "specializations": ["speech_therapy", "language_delay"],
  "qualifications": ["M.Phil Speech-Language Pathology, KIBGE"],
  "qualification_level": "mphil",
  "verified": true,
  "city": "Lahore",
  "area": "Gulberg",
  "lat": 31.5204,
  "lng": 74.3587,
  "rating": 4.8,
  "review_count": 64,
  "last_review_days_ago": 5,
  "on_time_rate": 0.94,
  "cancellation_rate": 0.03,
  "base_price": 2800,
  "age_ranges": ["preschool", "school_age"],
  "experience_years": 4,
  "available_slots": [
    "2026-05-19T16:00:00",
    "2026-05-22T16:00:00",
    "2026-05-26T16:00:00",
    "2026-05-29T16:00:00",
    "2026-06-02T16:00:00"
  ],
  "bio": "Specialized in pediatric speech-language therapy for children with autism and speech delays.",
  "languages": ["urdu", "english", "punjabi"]
}
```

**Variation guidelines:**
- Ratings: spread 3.8–4.9
- Cancellation rates: 2%–18% (varied to test ranking)
- ~60% verified, ~40% unverified
- Prices: 2000–5000 PKR
- Each gets 5 future slots over next 14 days
- ~70% female therapists (reflects pediatric therapy reality + tests gender preference)

> **AI: When generating the JSON, ensure varied data so ranking algorithm has meaningful differentiation. Don't make all therapists 4.5 stars.**

---

## 8. Mobile App Screens (Flutter)

### Screen 1: Home / Request Input

**Components:**
- App bar: **"NoorAI"** + crescent/light logo (simple SVG, no images needed)
- **Emotional subheading** (small, below logo): *"Pakistan's first AI therapist marketplace for special needs families"*
- Large TextField (multiline, hint: *"Apne bachay ke liye therapist describe karen..."*)
- 3 sample prompt chips below (tappable, fill the input):
  - "5 saal ke bete ko speech therapist chahiye Gulberg Lahore"
  - "Autism wali beti 7 saal F-8 Islamabad ABA therapist"
  - "ADHD 8 year old occupational therapist DHA Karachi"
- "Find Therapist →" button (primary, large)
- Subtle stat footer: *"🇵🇰 350,000+ children in Pakistan need therapy. Most families search on Facebook."*

**API call on submit:** `POST /api/find-therapists` with `{user_message: string}`

> **UX note:** The stat footer is not decorative — it is the hook for judges watching Screen 1. It frames the whole demo before a single button is tapped.

---

### Screen 2: Provider List (Ranked Results)

**Components:**
- Top bar: shows extracted intent as chips ("Speech Therapy", "Lahore Gulberg", "Age 5", "Budget 3000")
- "AI extracted this. Edit?" inline button
- Section header: "Top 3 matches"
- For each therapist card:
  - Photo placeholder + name + verification badge ✓
  - Overall score bar (e.g., 0.92 — green)
  - Top 3 factor highlights ("Speech Specialist ✓", "2.3km", "4.8★")
  - Per-session price (Rs 3,360)
  - Next available slot
  - "View Details" button
- Bottom: "See Agent Reasoning →" link to Screen 6

---

### Screen 3: Provider Detail

**Components:**
- Header: photo, name, specializations, verification badge
- Tabs: Overview | Reviews | Schedule | Price
- **Overview:** bio, qualifications, experience, age range expertise, languages
- **Reviews:** 3-5 mock reviews with dates
- **Schedule:** available slots (next 14 days), tappable
- **Price:** full breakdown widget:
  ```
  Base Rate          Rs 2,800
  Distance Surcharge Rs 0
  Urgency × 1.0
  Complexity × 1.2
  Loyalty Discount   −Rs 0
  ─────────────────────────
  Per Session        Rs 3,360
  Total (2 sessions) Rs 6,720
  ```
- "Book Now" button (primary)
- Floating "Why this match?" → opens Screen 6 filtered to this therapist

---

### Screen 4: Booking Confirmation

**Components:**
- Big green checkmark ✓
- "Booking Confirmed!" + confirmation code (NA-AYK-4291)
- Session schedule list with dates/times
- Therapist card mini
- Total paid (simulated): Rs 6,720
- **Simulated WhatsApp preview** (very important — looks like real WhatsApp message):
  ```
  [WhatsApp UI mock]
  NoorAI Bot · now
  
  Salam Sadia! Aap ka booking confirm ho 
  gaya hai. Dr. Ayesha Khan kal 19 May, 
  4:00 PM ko aap ke ghar aayegi...
  Confirmation code: NA-AYK-4291
  ```
- "View Follow-Up Schedule" → Screen 5
- "Done" button

---

### Screen 5: Follow-Up Timeline

**Components:**
- Vertical timeline of scheduled events
- For each event: icon, type, trigger time, preview message
- Examples:
  - 🔔 Reminder: 1 hour before Session 1 — "Dr. Ayesha 1 ghante mein..."
  - 📝 Feedback Request: 30 min after Session 1
  - 🔔 Reminder: 1 hour before Session 2
  - 📊 Progress Digest: After 4 sessions
  - 🔄 Renewal Nudge: After Session 8
- Each event tappable to see full simulated message
- Status indicators: Scheduled / Sent / Done

---

### Screen 6: Agent Trace (CRITICAL — THIS WINS THE DEMO)

**Components:**
- App bar: "How NoorAI decided" + back button
- **Inter-agent handoff arrows** — between each agent card, show a small animated arrow with the data being passed:
  ```
  [Intent Agent] ──→ { service: speech_therapy, city: Lahore, age: 5 } ──→ [Discovery Agent]
  [Discovery Agent] ──→ { 12 candidates found } ──→ [Ranking Agent]
  [Ranking Agent] ──→ { top 3 scored } ──→ [Pricing Agent]
  [Pricing Agent] ──→ { prices calculated } ──→ [Booking Agent]
  ```
  **Why:** This directly answers the judge's "Is there agentic reasoning?" question before they ask it. Most teams show a single LLM call. You show a pipeline.
- Vertical timeline of agent runs, each card:
  ```
  ┌─────────────────────────────────────┐
  │ 🧠 Intent Agent          [0.4s]     │
  │ ─────────────────────────────────── │
  │ Input: "Mere bete ko speech delay..."│
  │                                     │
  │ Reasoning:                          │
  │ Detected Roman Urdu. Extracted      │
  │ service=speech_therapy, age=5,      │
  │ city=Lahore, budget=3000.           │
  │ Confidence: 0.94                    │
  │                                     │
  │ Output: { service_type: ..., ... }  │
  └─────────────────────────────────────┘
        ↓ passed to Discovery Agent
  ┌─────────────────────────────────────┐
  │ 🔍 Discovery Agent        [0.2s]    │
  │ ...                                 │
  └─────────────────────────────────────┘
  ```
- Agents stream in (animated) as they complete
- **Total pipeline time** shown at bottom: "7 agents completed in 2.3s"
- "Replay" button at bottom
- **"Export Trace"** button — downloads the trace JSON (useful for README submission too)

**This screen IS the demo's hero moment. The inter-agent handoff visualization is what separates a "chatbot with steps" from a genuine agentic system in the judge's mind.**

---

### Screen 7: Dispute / Cancellation

**Components:**
- "Need help?" header
- Cards:
  - "Cancel booking" → Dispute Agent
  - "Therapist didn't show up" → Dispute Agent
  - "Price was different" → Dispute Agent
  - "Complain about service" → Dispute Agent
- After tap, shows Dispute Agent's resolution plan
- Example output for "Therapist cancelled":
  ```
  We found an alternative:
  Dr. Sara Ahmed
  4.7★ · 3.1km · M.Phil verified
  Same slot available ✓
  + 10% discount on next session
  
  [Confirm Rebook]  [Decline]
  ```

---

### Screen 8: Baseline Comparison

**Components:**
- App bar: "AI vs Traditional"
- Same query entered at top (read-only)
- Side-by-side cards:
  
  | Traditional System | TheraConnect AI |
  |---|---|
  | Closest first (distance only) | 8-factor weighted scoring |
  | "Physiotherapist 800m away" | "Dr. Ayesha 2.3km, pediatric speech specialist" |
  | ❌ Not specialized in speech | ✓ M.Phil speech-language pathology |
  | ❌ No age range data | ✓ Specializes in preschool/school age |
  | ❌ No price transparency | ✓ Full price breakdown shown |
  | ❌ No reasoning shown | ✓ Per-factor scores visible |

- Bottom takeaway: "Same query. Smarter answer."

---

## 9. Backend API Endpoints

```python
# main.py

@app.post("/api/find-therapists")
async def find_therapists(req: FindRequest):
    """
    Full pipeline: intent → discovery → ranking → pricing
    Returns ranked therapists with prices and a trace_id
    """
    pass

@app.post("/api/book")
async def book(req: BookingRequest):
    """
    Booking Agent: simulate booking, notification, follow-up
    Returns booking confirmation + trace_id
    """
    pass

@app.get("/api/trace/{trace_id}")
async def get_trace(trace_id: str):
    """
    Returns full agent trace for a session
    """
    pass

@app.post("/api/dispute")
async def dispute(req: DisputeRequest):
    """
    Dispute Agent: handle cancellation, no-show, etc.
    """
    pass

@app.post("/api/baseline-compare")
async def baseline_compare(req: FindRequest):
    """
    Returns both: traditional (distance-only) and AI (8-factor) results
    """
    pass
```

**Pydantic schemas:** `backend/models/schemas.py`

---

## 10. Stress Test Scenarios

### Scenario 2 (DEMO THIS): Therapist Cancels After Confirmation

**Implementation:**
1. After booking confirmation, expose admin endpoint `POST /api/admin/cancel-therapist/{booking_id}` that simulates the therapist cancelling
2. App polls `/api/booking-status/{booking_id}` every 5 seconds
3. When status flips to `therapist_cancelled`, Dispute Agent auto-fires
4. App shows notification → "Dr. Ayesha cancelled. Alternative found: Dr. Sara..."
5. User taps Confirm → rebooking simulated

**Why this demo:** Shows agent **autonomy + recovery + decision quality** in 30 seconds.

---

## 11. Baseline Comparison Logic

**Traditional algorithm (intentionally dumb):**
```python
def traditional_match(intent, all_therapists):
    # Just sort by distance, ignore everything else
    in_city = [t for t in all_therapists if t.city == intent.city]
    with_distance = [
        {**t, "distance": haversine(intent.location, t.location)}
        for t in in_city
    ]
    return sorted(with_distance, key=lambda x: x.distance)[:3]
```

**Show side-by-side on Screen 8.** Highlight differences.

---

## 12. README Skeleton

```markdown
# NoorAI — Pakistan's First Agentic Special Needs Therapy Marketplace

> *Every child is a light. NoorAI helps families find the right guide.*  
> Built for Google Antigravity Hackathon — Challenge 2.

## The Problem
350,000+ children in Pakistan are on the autism spectrum. Most families find therapists through WhatsApp groups and Facebook posts with no quality signals, no matching, and no follow-up.

## The Solution
NoorAI is a 7-agent agentic system that takes a natural language request in Urdu, Roman Urdu, or English — and within seconds delivers a ranked, priced, and booked therapy session with full follow-up automation.

## Architecture
[Diagram: 7 agents + Antigravity orchestrator + Flutter mobile app]

## Google Antigravity — Core Orchestration
NoorAI uses Antigravity as its **primary orchestration layer**, not as an add-on:
- All 7 agents are registered and executed inside Antigravity
- Each request generates an **Antigravity Workplan** (screenshot: /docs/antigravity/workplan.png)
- Each agent execution generates a **Tasks Plan** (screenshot: /docs/antigravity/tasks_plan.png)
- Agent Artifacts are exported and stored in /docs/antigravity/artifacts/
- Reasoning steps, decision flow, and action execution all flow through Antigravity

[Screenshots of Antigravity Workplan here]
[Screenshots of Tasks Plan here]

## 7 Agents Pipeline
1. **Intent Agent** — Multilingual NLP (Urdu/Roman Urdu/English) → structured intent
2. **Discovery Agent** — Filter 30 therapists by city, specialization, age range, radius
3. **Ranking Agent** — 8-factor weighted scoring with per-factor transparency
4. **Pricing Agent** — Dynamic pricing with full breakdown
5. **Booking Agent** — Simulated booking; writes to bookings.json
6. **Follow-Up Agent** — 5-event reminder/feedback schedule
7. **Dispute Agent** — Auto-recovery on cancellation; re-runs discovery pipeline

## Tech Stack
- Flutter (mobile app, Material 3)
- Python 3.11 + FastAPI (backend)
- Google Antigravity (orchestration — mandatory core)
- Gemini 2.0 Flash (LLM)
- JSON flat files (mock data store)

## Running Locally
1. Backend: `cd backend && pip install -r requirements.txt && uvicorn main:app --reload`
2. Mobile: `cd mobile && flutter run`

## Assumptions
- Mock therapist data (no real PII)
- Simulated bookings and WhatsApp notifications
- Single user per device (no auth in MVP)
- Locations approximate (Haversine against area centroids)

## Compliance
- ✅ No real personal data
- ✅ Disclaimer: "NoorAI connects families with therapists. It does not provide medical diagnosis."
- ✅ All mock
```

---

## 13. Demo Video Script (3.5 minutes) — OPTIMIZED FOR JUDGES

> **The demo video is not a tutorial. It is a pitch.** Structure it so judges feel the problem before they see the solution.

| Time | Scene | Action | Judge Criterion Hit |
|------|-------|--------|---------------------|
| 0:00–0:20 | Hook | Voiceover: *"In Pakistan, over 350,000 children are on the autism spectrum. Most families find therapists the same way — a post in a Facebook group, hoping someone replies."* Show: screenshot of Facebook group with unanswered post. | Innovation/UX (10%) — emotional setup |
| 0:20–0:40 | Problem sharpened | Show: WhatsApp conversation where parent asks for a therapist and gets 3 conflicting recommendations with no qualifications info, no price, no availability | Sets up the contrast |
| 0:40–0:50 | Introduce NoorAI | Show Screen 1. Speak: *"NoorAI. Powered by Google Antigravity. 7 agents. In your language."* | Innovation/UX |
| 0:50–1:10 | Input demo | Type Roman Urdu input live: *"Mere bete ko speech delay hai 5 saal ka hai Gulberg Lahore hafte mein 2 baar 3000 budget"* → tap Find. | Multilingual requirement |
| 1:10–1:40 | Agent Trace (Screen 6) | **Slow down here.** Show each agent firing in sequence with the handoff arrows. Narrate: *"Intent Agent detected Roman Urdu. Passed to Discovery. 8 factors scored. Pricing calculated. All inside Google Antigravity."* | **Antigravity (25%) + Agentic Reasoning (20%)** — the two biggest criteria |
| 1:40–2:00 | Results (Screen 2) | Show ranked list with score bars. Tap Dr. Ayesha → Screen 3 → price breakdown. *"Not sorted by distance. Sorted by 8 factors including qualifications, age fit, and cancellation rate."* | **Matching Quality (20%)** |
| 2:00–2:20 | Book → Confirm | Tap Book → Screen 4. Show confirmation + WhatsApp mock. *"Booking written. Notifications generated. Simulated end-to-end."* | **Action Simulation (15%)** |
| 2:20–2:50 | Stress Test LIVE | Trigger `POST /api/admin/cancel-therapist/BK-001`. App shows: *"Dr. Ayesha cancelled. Dispute Agent found Dr. Sara (4.7★, same slot) + 10% discount."* Tap Confirm. *"Autonomous recovery. No human intervention."* | **Agentic Reasoning (20%)** — autonomy proof |
| 2:50–3:10 | Baseline Compare (Screen 8) | Show side-by-side: distance-only gives wrong result; NoorAI's 8-factor gives right one. *"Same query. Smarter answer."* | **Matching Quality (20%)** — free points |
| 3:10–3:30 | Close | *"NoorAI. Built on Google Antigravity. 7 agents. Not a directory. A thinking system. For Pakistan's most underserved families."* Fade on NoorAI logo + نور | Emotional close |

> **Key demo discipline:** Never spend more than 10 seconds on any one screen except Screen 6. That screen is worth 45% of the score. Slow. Down. There.

---

## 14. 3-Day Sprint Plan

> ⚠️ **Today is Day 3 (May 19). Submission is May 20. This is the final push.**

### Day 1 (May 17) — Foundation ✅
- [x] Antigravity setup + quickstart
- [x] Generate 30-therapist JSON dataset
- [x] Build Intent Agent (test on 10 inputs)
- [x] Flutter project + 8 empty screens with navigation
- [x] Backend FastAPI skeleton

### Day 2 (May 18) — Core Pipeline ✅
- [x] Discovery + Ranking Agents
- [x] Pricing + Booking Agents
- [x] Notification + Follow-Up Agents
- [x] Wire all via Antigravity, capture trace
- [x] Flutter UI for Screens 1, 2, 3, 6

### Day 3 (May 19) — Polish + WIN 🎯
- [ ] **PRIORITY 1:** Dispute Agent + Stress Test 2 (cancellation flow)
- [ ] **PRIORITY 2:** Screen 6 inter-agent handoff arrows (animated)
- [ ] **PRIORITY 3:** Screen 8 Baseline Compare
- [ ] **PRIORITY 4:** Screens 4, 5, 7 (functional, not polished)
- [ ] Visual polish on demo-critical screens (1, 2, 6, 8 ONLY)
- [ ] Export Antigravity Workplan + Tasks Plan screenshots → add to README
- [ ] Demo video record (aim for 5 takes, pick best)
- [ ] Build APK + verify on physical device
- [ ] README + architecture diagram + ANTIGRAVITY_WALKTHROUGH.md
- [ ] **Submit by May 20, 4 PM** (8 hours before deadline — do not wait for deadline)

---

## 15. Coding Rules for AI

When using AI tools (Cursor, Claude Code, Antigravity) with this spec:

1. **Always paste this file as context** before generating code
2. **One agent at a time** — don't try to build the whole pipeline in one shot
3. **Test Intent Agent first** with all 5 example inputs (section 6.1) before moving on
4. **Use exact schemas** — don't let AI invent new field names
5. **Mock everything** — no real APIs, no real auth, no real DB
6. **Keep Flutter screens dumb** — all logic in backend; mobile just displays
7. **Antigravity traces are NON-NEGOTIABLE** — every agent run must log to traces.json
8. **Build Screen 6 (Agent Trace) before Screen 4 (Booking)** — it's the demo hero
9. **Baseline screen is free points** — don't skip it
10. **No fancy animations** — clean, readable, fast. Polish only the 4 demo-critical screens (1, 2, 6, 8)

---

## 16. Demo-Critical vs Nice-to-Have

**Must be polished (judges will see):**
- Screen 1 (Home)
- Screen 2 (Provider List)
- Screen 6 (Agent Trace) ← THE HERO
- Screen 8 (Baseline Compare)
- The cancellation stress test flow

**Can be minimal (functional but plain):**
- Screen 3 (Provider Detail)
- Screen 4 (Booking Confirmation)
- Screen 5 (Follow-Up Timeline)
- Screen 7 (Dispute Screen)

---

## 17. Risks & Mitigations

| Risk | Mitigation |
|------|-----------|
| Antigravity learning curve too steep | Allocate Day 1 morning for tutorials only |
| APK build fails | Build by end of Day 2, not Day 3 |
| Demo bug live | Pre-record video as safety net |
| Sensitive topic handled clumsily | Add disclaimer; respectful language throughout |
| Gemini misinterprets Urdu edge case | Always show extracted intent for confirmation when confidence < 0.85 |
| Solo workload too heavy | Cut to 4 polished + 4 minimal screens |

---

## 18. Compliance Reminders

- ❌ No real personal data (use mock)
- ❌ No diagnosis claims (add disclaimer: "TheraConnect connects families with therapists; it does not provide medical diagnosis.")
- ✓ Multilingual input (Urdu/Roman Urdu/English)
- ✓ 8 matching factors (exceeds 6+ requirement)
- ✓ Antigravity central to orchestration
- ✓ Agent trace visible
- ✓ Baseline comparison built
- ✓ Stress test demoed
- ✓ Mobile APK as deliverable

---

## 19. Final Note for AI Coders

> **This is a hackathon project, not a production app.**  
> Build for the **demo**, not for scale. Optimize for what judges see in 3.5 minutes.  
> The judges score on: Antigravity usage (25%), Agentic reasoning (20%), Matching quality (20%), Action simulation (15%), Tech implementation (10%), Innovation/UX (10%).  
> Every line of code should map to one of these. If it doesn't, skip it.

**The name is NoorAI everywhere:** app bar, README title, confirmation codes (NA- prefix), WhatsApp mock sender, demo video closing card.

**The three things that will make you win:**
1. **Screen 6 with inter-agent handoffs** — it's visual proof of agentic reasoning; no other team will have it
2. **Antigravity Workplan + Tasks Plan screenshots in README** — it's explicitly in the challenge rubric and most teams will miss it
3. **The emotional hook** — you're not booking a plumber, you're helping a parent find help for their child. The judges will feel that difference even if they don't articulate it.

**End of spec. Now build NoorAI.**
