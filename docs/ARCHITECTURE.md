# NoorAI Architecture

NoorAI relies on a centralized multi-agent orchestration architecture using Google Antigravity as the core engine.

```mermaid
graph TD
    User((User)) --> MobileApp(Flutter Mobile App)
    MobileApp -->|HTTP POST| FastAPI(Backend Server)
    
    subgraph "Google Antigravity Orchestrator"
        FastAPI --> Orch[Antigravity Runner]
        
        Orch --> IA[Intent Agent]
        IA -->|NLP parsing| DA[Discovery Agent]
        DA -->|Filters mock DB| RA[Ranking Agent]
        RA -->|8-factor scoring| PA[Pricing Agent]
        PA -->|Dynamic calculation| Orch
        
        Orch -->|Select Top Match| BA[Booking Agent]
        BA -->|Simulate Booking| NA[Notification Agent]
        NA -->|Generate mock WhatsApp| FA[Follow-Up Agent]
        FA -->|Schedule 5 events| Orch
        
        Orch --> DispA[Dispute Agent]
        DispA -.->|Re-run Pipeline| DA
    end
    
    Orch -->|Return Trace JSON| FastAPI
    FastAPI -->|Display Agent Trace| MobileApp
    
    subgraph "Data Storage (JSON Mock)"
        DB1[(therapists.json)]
        DB2[(bookings.json)]
        DB3[(traces.json)]
        
        DA -.-> DB1
        BA -.-> DB2
        Orch -.-> DB3
    end
```

## System Components
1. **Flutter Mobile App**: Contains the frontend screens including Home, Results, Agent Trace, Dispute, and Baseline Comparison.
2. **FastAPI Backend**: Acts as a bridge between the mobile app and the Antigravity Orchestrator. 
3. **Google Antigravity Runner**: The core orchestration mechanism ensuring that the Workplan and Tasks Plan are properly executed and handed off between agents.
4. **Mock DBs**: Instead of a full relational DB, we're using mock JSON datasets to enable quick testing, local-only runs, and predictable demos.
