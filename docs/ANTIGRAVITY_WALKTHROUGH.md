# Google Antigravity Walkthrough

This document outlines how NoorAI uses Google Antigravity to orchestrate a 7-agent pipeline. 
This is not a bolted-on API call, but a core architectural choice that drives the entire application.

## Antigravity Workplan
When a user submits a natural language request, the Antigravity Orchestrator generates a Workplan that includes:
1. **Understanding the Intent**: Passing raw text to the Intent Agent.
2. **Matching & Scoring**: Activating the Discovery Agent and Ranking Agent.
3. **Execution**: Passing finalized choices to the Booking and Notification Agents.

![Antigravity Workplan](/docs/antigravity/workplan.png) 
*(Note: Placeholder for actual screenshot exported from Antigravity Console)*

## Tasks Plan
For each step in the Workplan, Antigravity generates a specific Tasks Plan with explicit expected schemas and parameters. 
- The Intent Agent returns `{ service_type, condition, child_age, city }`
- The Ranking Agent returns `{ ranked_therapists, reasoning }`

![Antigravity Tasks Plan](/docs/antigravity/tasks_plan.png)
*(Note: Placeholder for actual screenshot exported from Antigravity Console)*

## Trace Artifacts
The entire execution pipeline is recorded in `backend/data/traces.json`. The Flutter application parses this JSON to generate the "How NoorAI Decided" screen (Screen 6), exposing the inter-agent handoffs with detailed reasoning.
