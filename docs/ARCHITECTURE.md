# Architecture

NoorAI employs a system of 7 Specialized Agents running via Google Antigravity.

1. **Intent Agent**: Parses natural language (Urdu/English/Roman Urdu) into structured service intent.
2. **Discovery Agent**: Filters candidates from the database (distance, service, age match).
3. **Ranking Agent**: Computes an 8-factor score (specialization, age range fit, qualifications, distance, rating, reliability, price vs budget, cancellation rate).
4. **Pricing Agent**: Computes dynamic pricing based on distance, urgency, and complexity.
5. **Booking Agent**: Simulates optimistic slot locking and transaction confirmation.
6. **Notification Agent**: Generates simulated contextual SMS/WhatsApp messages to therapists and parents.
7. **Follow-Up Agent & Dispute Agent**: Post-booking schedule management and dispute resolution (e.g. handling therapist cancellation and re-booking).
