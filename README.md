# Meridian Building Solutions — Agentforce Portfolio

## What this is

**Meridian Building Solutions** is a mock mid-market commercial HVAC and building automation company, built out end-to-end in a free Salesforce Agentforce + Data Cloud (Data 360) Developer Edition org as a portfolio piece. This repo is Project 1 of a three-project arc: a customer-facing **Agentforce Service Agent** deployed on an authenticated Experience Cloud portal. Logged-in customers (facility managers, building engineers) ask it about their service contract coverage, upcoming maintenance visits, technicians, inspection results, and equipment health, get general how-does-this-work answers grounded in a Knowledge base, and can submit non-urgent service requests directly through the conversation. It exists to demonstrate real Agentforce + Data Cloud build skills — agent design, custom action flows, RAG grounding, and Calculated Insights — to engineers and hiring managers evaluating that experience, not to run an actual business.

## Architecture

```mermaid
flowchart TB
    User(["Portal User (Contact)<br/>e.g. Joshua Martinez"]) --> EM(["Embedded Messaging<br/>(Experience Cloud site)"])
    EM --> Router{{"agent_router<br/>(classifies on subagent descriptions)"}}

    Router --> FAQ["GeneralFAQ"]
    Router --> Info["Account_Service_Info"]
    Router --> Req["Service_Requests"]
    Router --> Esc["escalation"]
    Router --> Off["off_topic"]

    FAQ --> Prompt["Meridian_Answer_From_Knowledge<br/>(prompt template)"]
    Info --> A1["Get_Contract_Coverage"]
    Info --> A2["Get_Next_Visit"]
    Info --> A3["Get_Last_Inspection"]
    Info --> A4["Get_Equipment_Health"]
    Req --> A5["Submit_Service_Request (write)"]
    Esc --> Human(["Live agent handoff<br/>(Omni-Channel Queue + Routing Config)"])

    subgraph CRM["Salesforce CRM — flows run system-context, no sharing"]
        direction TB
        SC[("Service_Contract__c")]
        MV[("Maintenance_Visit__c")]
        IR[("Inspection_Report__c")]
        EA[("Equipment_Asset__c")]
        CS[("Case")]
    end

    A1 -->|"filtered by ContactId&nbsp;&rarr;&nbsp;AccountId"| SC
    A2 -->|"filtered by ContactId&nbsp;&rarr;&nbsp;AccountId"| MV
    A3 -->|"filtered by ContactId&nbsp;&rarr;&nbsp;AccountId"| IR
    A4 -->|"filtered by ContactId&nbsp;&rarr;&nbsp;AccountId"| EA
    A5 -->|"AccountId + ContactId from resolved identity"| CS

    subgraph DataCloud["Data Cloud / Data 360"]
        direction TB
        Retriever["Meridian_KB_Body_Index Retriever"]
        Index["Search Index<br/>(chunks Article_Body__c only)"]
        KDMO[("ssot__KnowledgeArticleVersion__dlm")]
        Tele[("Equipment_Telemetry_Aggregates__cio")]
        Fault[("Equipment_Fault_Aggregates__cio")]
        Health[("Equipment_Health_Score__cio")]
        Sync["Sync_Health_Score_To_CRM<br/>(Data Cloud-triggered flow)"]
    end

    Prompt --> Retriever --> Index --> KDMO
    KAV[("Knowledge__kav<br/>(10 published articles)")] --> KDMO

    Tele --> Health
    Fault --> Health
    Health --> Sync --> EA

    classDef touchpoint fill:#d4a548,stroke:#8a6423,stroke-width:2px,color:#1b3a5c,font-weight:bold
    classDef router fill:#1b3a5c,stroke:#0f2847,stroke-width:2px,color:#ffffff,font-weight:bold
    classDef subagent fill:#2d5f8a,stroke:#1b3a5c,stroke-width:1.5px,color:#ffffff
    classDef action fill:#3d76a8,stroke:#1b3a5c,stroke-width:1.5px,color:#ffffff
    classDef datastore fill:#eef3f8,stroke:#1b3a5c,stroke-width:1.5px,color:#1b3a5c

    class User,EM,Human touchpoint
    class Router router
    class FAQ,Info,Req,Esc,Off subagent
    class Prompt,A1,A2,A3,A4,A5,Retriever,Index,Sync action
    class SC,MV,IR,EA,CS,KDMO,Tele,Fault,Health,KAV datastore

    style CRM fill:#f5f8fb,stroke:#1b3a5c,stroke-width:1.5px
    style DataCloud fill:#fbf7ec,stroke:#8a6423,stroke-width:1.5px

    linkStyle 14,15,16,17,18 stroke:#d4a548,stroke-width:2.5px
```

_Gold edges trace the identity/security boundary — the `ContactId → AccountId` filter is the only thing standing between a portal user and another customer's data (see below). Cylinders are data at rest; the hexagon is the routing decision point; rectangles are process/action steps._

The Knowledge grounding path (bottom-left of the Data Cloud box) and the Equipment Health Score write-back path (bottom-right) are independent Data Cloud pipelines that both land back in the CRM objects the agent's action flows read — Knowledge indirectly through the retriever, equipment health directly through the CI write-back flow. Data Cloud also holds a separate three-stage `Account_Risk_Score__cio` pipeline (`Account_Portal_Aggregates__cio` + `Account_Case_Aggregates__cio` → `Account_Risk_Score__cio`); it's built and verified but not yet consumed by any agent — it's the primary input for the not-yet-started Project 2 (Renewal Prep Agent) and is omitted above since nothing in this repo reads it yet.

## Design decisions and tradeoffs

### ⭐ Identity and security model

Action flows run **as the portal user** (confirmed via flow debug log — not as the auto-provisioned Agentforce service-agent user), but in **system context without sharing ("Access All Data")**, because the portal user's own profile has no access to the custom objects at all. That means there is no sharing layer sitting behind these flows — **the in-flow `ContactId → AccountId` filter, derived solely from the authenticated session, is the entire security boundary.**

This was chosen deliberately over the alternative — granting the portal user direct object access plus sharing sets — for two reasons:

- **Customer Community Plus has a known defect** where child records granted via a sharing set on the parent don't cascade down the hierarchy (Account → Site → Equipment → Visits/Inspections here). System-context flows sidestep it entirely instead of fighting it.
- It keeps the portal user's own object access minimal, so a future loosening of org-wide defaults can't accidentally expose other accounts' data — every read of account-scoped data goes through one auditable filter instead of being spread across a sharing model.

The flows were built with a defensive three-tier identity resolution (`ContactIdInput` bound to a messaging session variable → `$User.ContactId` → a test fallback), but in production `MessagingEndUser.ContactId` is null for this channel type (authenticated site login and verified messaging identity are separate concepts), so **`$User.ContactId` is the actual production path**. The third tier — `TestAccountId`/`TestContactId` inputs — was **deliberately removed** once the no-sharing model was in place, because under no-sharing they amounted to a live "set any account, read any account" bypass with no guardrail behind them. They must never be reintroduced to any new action flow.

**Correction on scope of that guarantee:** an earlier version of the design doc claimed portal users have "zero direct object access." That's no longer literally true — the portal profile was later granted object read plus field-level security on `Knowledge__kav` (specifically `Article_Body__c` and `Category__c`), so an interviewer could catch a "zero access" claim that doesn't hold up. The accurate framing: _portal users have no access to any account-scoped object — contracts, equipment, visits, inspections all route through account-scoped flows in system context. The one direct grant is Knowledge, which is deliberately non-account-specific: the same ten articles are visible to every customer, so there's nothing to scope and no sharing model to get wrong by granting it._

### ⭐ Staged Calculated Insights, to avoid a JOIN fan-out

Both major Data Cloud metrics in this org — Equipment Health Score and (for the not-yet-built Project 2) Account Risk Score — are built as **three staged Calculated Insights** rather than one. For Equipment Health Score: `Equipment_Telemetry_Aggregates__cio` (999 rows, one per monitored unit) and `Equipment_Fault_Aggregates__cio` (881 rows) each pre-aggregate their own high-volume source independently, and a third CI (`Equipment_Health_Score__cio`) reads both staged outputs and combines them.

The reason is a **JOIN fan-out problem**: telemetry has 29,970 raw readings and faults have 1,490 raw events across 999–1,181 pieces of equipment. Joining those two high-volume, high-cardinality sources directly in a single CI multiplies rows incorrectly before aggregation ever happens. Aggregating each source down to one row per equipment first, then joining the two already-aggregated stage tables, avoids the fan-out entirely. The tradeoff is more CIs to build, publish, and keep in sync — accepted because getting the row multiplication wrong would silently corrupt the health score.

### ⭐ Agentforce Data Library abandoned in favor of a manual search index

Knowledge grounding was first built on the low-code **Agentforce Data Library (ADL)** path, then abandoned. The ADL auto-chunks multiple Knowledge fields at once (title, URL name, summary, article number, body) with no field-level control — attempting to restrict it to "body only" does nothing. In practice this produced thin title-only and metadata-only chunks alongside real body chunks, and because a bare title chunk is a near-perfect embedding match for a title-shaped query (e.g. "how do I submit a service request"), **the content-free chunks routinely outranked the real content**.

The fix was to build the search index manually via **Data 360 → Search Index → Advanced Setup**, which has an explicit "Select Fields to Chunk" step — chunking `Article_Body__c` only. That produced exactly 10 clean chunks (one per article), with the correct article ranking #1 on every probe question tested. One extra gotcha worth flagging: the ADL reuses an existing search index whenever a new library shares the same identifying fields, so simply re-running the ADL setup kept returning the same broken chunks — the old ADL and its retriever/index/chunk DMOs had to be deleted outright before the manual index would take over cleanly.

### ⭐ Custom actions over the standard query/summarize actions

Per Salesforce's own guidance for public-facing agents, this build uses **five purpose-built Flow actions** (`Get_Contract_Coverage`, `Get_Next_Visit`, `Get_Last_Inspection`, `Get_Equipment_Health`, `Submit_Service_Request`) instead of the platform's generic query/summarize actions. Each one is deterministic, scoped to exactly the fields and objects it needs, account-scoped by construction (see the identity model above), and independently testable — a prompt can't redirect a purpose-built flow into querying an arbitrary object or field the way it could a generic "query records" action.

This also sidesteps a specific fragility in the standard tooling: the out-of-the-box `AnswerQuestionsWithKnowledge` action depends on a RAG/Data Library configuration reference, and if that library is ever deleted, the action fails silently with no error surfaced to the builder. Grounding `GeneralFAQ` on a custom prompt template bound to a specific retriever, rather than the standard knowledge action, avoided that same class of silent failure.

### Other notable decisions

- **The Agentforce router classifies on subagent _descriptions_ only** — instructions written into a subagent are never read at routing time. Getting the description wording right (e.g. `GeneralFAQ` explicitly claims "how to submit a request" questions, `Account_Service_Info` owns possessive "my record" questions) was the single biggest source of routing bugs during the build.
- **Case creation defaults are hardcoded, not LLM-set**: `Priority` is fixed at `Low` so customer insistence can't inflate routing priority, and `Type` is left for human triage since trade classification isn't something a customer can self-diagnose.
- **Emergency vs. insistence guardrails were tuned after a real test failure** where "extremely urgent" phrasing over-escalated a comfort complaint. Only explicit safety hazards (no heat/cooling in a critical space, gas/refrigerant leak, water intrusion, smoke) redirect to the emergency line without writing a Case; urgency language alone does not.
