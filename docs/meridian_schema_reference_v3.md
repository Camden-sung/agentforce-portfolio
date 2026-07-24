# Meridian Building Solutions — Salesforce Schema & Org Reference (v3)

> Context doc for Claude conversations about building Agentforce agents on this org.
> **Last updated:** **Project 1 (Customer Service Portal Q&A Agent) COMPLETE and live on Experience Cloud.**
> Phase 1 Data Cloud foundation complete; both Phase 2 Calculated Insights complete & verified; Project 1's retriever, Knowledge content, agent, action flows, and portal deployment all built and verified end-to-end as a real external user.
> **Remaining:** Project 2 (Renewal Prep Agent) and its retrievers; Project 3 (stretch) streaming/Data Actions.

**Changes from v2:** Knowledge section rewritten (v2's "38 articles loaded" was aspirational — Lightning Knowledge was never enabled); Equipment Health Score write-back is now **implemented** (v2 said it was not); new Project 1 as-built section; new lessons-learned sections for Flow, Agentforce, and Experience Cloud; inspector name corrected to **Adam** Morris.

---

## Project context

**Meridian Building Solutions** is a mock mid-market commercial HVAC and building automation company (Charlotte NC HQ, ~850 employees, ~$240M revenue, regional offices in Atlanta, Dallas, Nashville, Tampa). Sells, installs, and services HVAC + building automation for hospitals, schools, Class A offices, manufacturing, multi-site retail. Revenue mix: ~40% new system sales/install, ~45% recurring service contracts and PM, ~15% emergency/on-demand service.

This is a **portfolio org** for demonstrating Agentforce + Data Cloud (Data 360) capabilities to potential employers. Built on a free Agentforce + Data Cloud Developer Edition org (5MB CRM data storage limit).

Three agent projects, escalating in complexity:

1. **Project 1 — Customer Service Portal Q&A Agent** (Experience Cloud, customer-facing). ✅ **COMPLETE — see the Project 1 section below.**
2. **Project 2 — Renewal Prep Agent** (internal, AE-facing). Given an upcoming contract renewal, pulls service history, open cases, equipment age, contract margin, and produces a renewal brief + drafted outreach. Uses the Data Cloud unified customer profile + `Account_Risk_Score__cio`. Demonstrates Identity Resolution. **Not started.**
3. **Project 3 — Autonomous Service Orchestration Agent** _(stretch — may be cut)_. Triggered by a Data Cloud Data Action when telemetry crosses thresholds. **Not started.**

> **Terminology note:** Salesforce rebranded Data Cloud to **Data 360** (platform: Agentforce 360). This doc uses both; they are the same product. The **new Agentforce agent builder** went GA Feb 2026 — older Trailhead/blog walkthroughs often describe the legacy builder and will not match the UI.

---

## CURRENT ORG STATE

**CRM data: fully loaded.** Data Loader used with upsert + External ID matching.

| Object                       | Records                                 | Notes                                                                |
| ---------------------------- | --------------------------------------- | -------------------------------------------------------------------- |
| Account                      | 50                                      |                                                                      |
| Contact                      | 152                                     | `Email` set as External ID + Unique                                  |
| User                         | 4 active + 1 agent user + 1 portal user | see user pool below                                                  |
| Site__c                      | 126                                     |                                                                      |
| Service_Contract__c          | 50                                      | 9 in "Pending Renewal" — Project 2 demo targets                      |
| Equipment_Asset__c           | 1,181                                   |                                                                      |
| Maintenance_Visit__c         | 500                                     | trimmed from 3,000                                                   |
| Inspection_Report__c         | 76                                      | trimmed from 600                                                     |
| Case                         | 100                                     | trimmed from 160; **+ any live cases submitted by the portal agent** |
| Knowledge (`Knowledge__kav`) | **10 published articles**               | **real content**, customer-visible — see Project 1                   |

Org data storage ~4.4MB of the 5MB limit.

**User pool:**

| Role               | Username                              | Used as                                                                     |
| ------------------ | ------------------------------------- | --------------------------------------------------------------------------- |
| Primary AE (admin) | (your admin username)                 | `Service_Contract__c.Account_Executive__c` on most contracts                |
| Secondary AE       | `rwilliams.ae@meridianhvac.com.demo`  | `Account_Executive__c` on ~40% of contracts                                 |
| Technician         | `mjohnson.tech@meridianhvac.com.demo` | **Marcus Johnson** — `Maintenance_Visit__c.Technician__c` on ALL 500 visits |
| Inspector          | `amorris.insp@meridianhvac.com.demo`  | **Adam Morris** — `Inspection_Report__c.Inspector__c` on all inspections    |
| Agent user         | `service_agent_test@…​.ext`           | EinsteinServiceAgent user, auto-provisioned with the agent                  |
| Portal user        | Joshua Martinez                       | Customer Community Plus, Highland Tower Holdings — Project 1 demo persona   |

> Only ONE technician exists (DE license limit). Admin user required a **role** (set to CEO) before contacts could be enabled as portal users.

**Data Cloud / Data 360:** Phase 1 foundation + both Phase 2 Calculated Insights complete. Project 1's retriever built (Phase 2 item 10, partially done — Project 2's retrievers still outstanding).

**Data Space:** `default`. Everything lives here — do not create a second Data Space.

---

## Standard objects used

- **Account** — custom field `External_ERP_Customer_Id__c` (Text 50, External ID, Unique), values `ERP-CUST-00001`..`00050`.
- **Contact** — `Email` is External ID + Unique; join key for portal/CSR Data Cloud sources.
- **User** — see pool above.
- **Case** — service requests. **Picklist values confirmed in-org:**
  - Origin: `Phone`, `Email`, `Web` _(no Chat/Agent value — agent-created cases use `Web`)_
  - Status: `New`, `Working`, `Escalated`, `Closed`
  - Priority: `High`, `Medium`, `Low`
  - Type: `Mechanical`, `Electrical`, `Electronic`, `Structural`, `Other`
- **Knowledge (`Knowledge__kav`)** — see Project 1 Knowledge section. **The stock Knowledge object has no body field**; a custom one was added.

---

## Custom objects

Build dependency order: Site → Service_Contract → Equipment_Asset → Maintenance_Visit → Inspection_Report.
(Full field lists unchanged from v2 — abbreviated here to the fields Project 1 actually reads.)

### `Site__c`

`Account__c` (Lookup → Account), `Primary_Contact__c`, `Site_Type__c`, `Site_Criticality__c`, address fields, `External_System_ID__c` (`BAS-SITE-00001`..).

### `Service_Contract__c` — record name `SC-{00000}`

`Account__c`, `Account_Executive__c`, `Contract_Type__c`, `Coverage_Level__c` (Bronze/Silver/Gold/Platinum), `Contract_Status__c`, `Start_Date__c`, `End_Date__c`, `Annual_Contract_Value__c`, `Number_of_PM_Visits_Per_Year__c`, `Includes_Emergency_Service__c`, `Response_SLA_Hours__c`, `Contract_Margin__c`, `External_System_ID__c` (`ERP-CTR-00001`..).

**Coverage tier profile (measured across all 50 contracts — clean and monotonic):**

| Tier     | PM visits/yr | Emergency service | Response SLA |
| -------- | ------------ | ----------------- | ------------ |
| Bronze   | 1            | No                | 24 hr        |
| Silver   | 2            | Yes               | 8 hr         |
| Gold     | 4            | Yes               | 4 hr         |
| Platinum | 4            | Yes               | 2 hr         |

_These numbers are stated verbatim in the Knowledge articles, so article content and record lookups always agree._

### `Equipment_Asset__c` — record name `EQ-{00000}`

`Site__c` (Lookup), `Account__c` (**Text formula** — `Site__r.Account__c`), `Equipment_Type__c`, `Manufacturer__c`, `Serial_Number__c`, `Install_Date__c`, `Capacity_Tons__c`, `Equipment_Status__c`, `Criticality__c`, `Last_Service_Date__c`, `Next_Scheduled_Service_Date__c`, `External_System_ID__c` (`EQ-000001`..).

- **`Equipment_Health_Score__c` (Number 3,0) — NOW LIVE-DRIVEN.** No longer mock seed values. Populated from `Equipment_Health_Score__cio`; see the write-back section. **NULL = equipment not telemetry-monitored** (182 of 1,181 units). Mock seeds were deliberately cleared so null is an honest signal.
- **`Equipment_Type__c` picklist (exact values — the agent must pass these verbatim):**
  `Rooftop Unit (RTU)`; `Chiller`; `Boiler`; `Air Handler (AHU)`; `VAV Box`; `Cooling Tower`; `Heat Pump`; `Building Automation Controller`; `Pump`; `Fan/Exhaust`; `Split System`; `Package Unit`

### `Maintenance_Visit__c` — record name `MV-{000000}`

`Equipment__c` (Lookup), `Service_Contract__c` (Lookup), `Site__c` / `Account__c` (**Text formulas**), `Technician__c` (Lookup → User), `Visit_Type__c`, `Visit_Status__c`, `Scheduled_Start__c`/`End__c`, `Actual_Start__c`/`End__c`, `Visit_Outcome__c`, `Labor_Hours__c`, `Total_Cost__c`, `External_System_ID__c` (`FSA-xxxxxxx`).

### `Inspection_Report__c` — record name `IR-{00000}`

`Equipment__c` (Lookup), `Maintenance_Visit__c` (Lookup), `Site__c` / `Account__c` (**Text formulas**), `Inspector__c` (Lookup → User), `Inspection_Date__c`, `Inspection_Type__c`, `Overall_Condition__c`, `PassFail__c`, `Compliance_Status__c`, `Findings__c`, `Recommendations__c`, `Recommended_Action__c`, cost estimates, `Next_Inspection_Due_Date__c`. **No `External_System_ID__c`** — loaded via Insert; re-loading duplicates.

**Confirmed picklist value sets (used verbatim in the "How to Read Your Inspection Report" article):**

- Overall Condition: Excellent / Good / Fair / Poor / Critical
- PassFail: Pass / Conditional Pass / Fail
- Compliance: Compliant / Non-Compliant / Conditional / Not Applicable
- Recommended Action: No Action Required / Continued Monitoring / Schedule Repair / Schedule Replacement / Immediate Action Required

> ⚠️ **`Account__c` and `Site__c` on Maintenance_Visit / Inspection_Report / Equipment_Asset are formula (text) fields, not real lookups.** See the Flow lessons — they store **15-character** IDs and require normalization when filtered.

---

## Data Cloud / Data 360 — AS BUILT

_(Unchanged from v2 except where noted. Abbreviated; see v2 for full DLO/DMO field mapping detail.)_

### Source files and DLOs (all bulk-ingested)

| CSV                                | Rows   | DLO                   | Category   | Primary Key       |
| ---------------------------------- | ------ | --------------------- | ---------- | ----------------- |
| `erp_ar_aging.csv`                 | 50     | `ERP_AR_Aging`        | Other      | `erp_customer_id` |
| `erp_invoices.csv`                 | 449    | `ERP_Invoices`        | Other      | `invoice_id`      |
| `erp_parts_inventory.csv`          | 35     | `ERP_Parts_Inventory` | Other      | `part_number`     |
| `portal_engagement.csv`            | 1,834  | `Portal_Engagement`   | Engagement | `event_id`        |
| `csr_call_log.csv`                 | 221    | `CSR_Call_Log`        | Engagement | `call_id`         |
| `telemetry_equipment_readings.csv` | 29,970 | `Equipment_Telemetry` | Engagement | `reading_id`      |
| `telemetry_fault_codes.csv`        | 1,490  | `Equipment_Fault`     | Engagement | `fault_event_id`  |

Coverage: telemetry covers **999**/1,181 equipment; faults cover 881; portal/CSR cover ~48/50 accounts.

### DMOs (13) and Relationships (8)

Custom DMOs for domain data (`*_DMO__dlm`), standard DMOs for identity anchors (Account, Individual, Contact Point Email, Case). CRM connector DLOs use a `_Home` suffix. Join keys: `External_ERP_Customer_Id__c` (Account), `Email` (Contact Point Email), `External_System_ID__c` (Equipment). **Knowledge was added to Data 360 for Project 1** — see below.

### Identity Resolution

Ruleset `Customer_Identity_Resolution`, ID `INDV`, primary DMO Individual. Single match rule: **Email Exact** via Contact Point Email. Outputs: Unified Individual (152), Unified Contact Point Email (152). Downstream retrievers/segments should target the **Unified** DMOs.

### Calculated Insights

**Equipment Health Score — 3 staged CIs** (staging avoids telemetry × fault JOIN fan-out):

1. `Equipment_Telemetry_Aggregates__cio` (999 rows) — `AvgVibration__c`, `SetpointDeviationSq__c`, `ReadingCount__c`
2. `Equipment_Fault_Aggregates__cio` (881 rows) — `ActiveFaultScore__c` (Critical=10/Major=4/Minor=1), `ActiveFaultCount__c`, `TotalFaultCount__c`
3. **`Equipment_Health_Score__cio`** (999 rows) — dimension `EquipmentId__c`, measure `HealthScore__c`

```
HealthScore = 100
  − max(0, (AvgVibration        − 0.9) × 25)
  − max(0, (SetpointDeviationSq − 2.5) × 3)
  − (ActiveFaultScore × 2.5)
  , floored at 0
```

Verified: min 13.41, max 100, mean 90.71.

**Account Risk Score — 3 staged CIs.** `Account_Portal_Aggregates__cio` (48) + `Account_Case_Aggregates__cio` + **`Account_Risk_Score__cio`** (50 rows, min 0 / max 84 / mean 14.02). Dimension = ERP customer id. **Higher = more risk.** Project 2's primary signal. Unchanged from v2.

> ⚠️ **Test cases submitted through the portal agent land on real accounts and inflate `Account_Case_Aggregates` open-case counts.** Delete test cases (especially on Highland Tower) or Project 2's risk score will be skewed.

### ✅ Equipment Health Score write-back — IMPLEMENTED (v2 said this was not built)

v2 documented the write-back as impossible via Copy Field Enrichment and deferred it. Project 1 needed the score readable from a Flow, which forced the issue. **Resolution: a Data Cloud-Triggered Flow + a one-time Data Loader backfill.**

- **`Sync_Health_Score_To_CRM`** — Data Cloud-Triggered Flow on `Equipment_Health_Score__cio`, Data Space `default`, trigger = created or updated, entry condition `HealthScore__c >= 0`. One Update Records element: `Equipment_Asset__c` where `External_System_ID__c Equals {!$Record.EquipmentId__c}`, setting `Equipment_Health_Score__c = ROUND({!$Record.HealthScore__c}, 0)`.
- **Backfill (required, one-time):** triggered flows fire on _change_ and do **not** backfill existing rows — re-publishing an unchanged CI emits no events. Existing 999 rows were loaded by exporting the CIO from the Data 360 Query Editor (`SELECT EquipmentId__c, HealthScore__c FROM Equipment_Health_Score__cio`), rounding to whole numbers, and **Data Loader Upsert** on `Equipment_Asset__c` matching `External_System_ID__c`.
- **Seeds cleared first** so that NULL honestly means "not monitored." Spot check: `EQ-000784` seed was 88, live CI value is **100**.
- **Why this instead of a live query:** Flow's Get Records **cannot query a CIO** (see Flow lessons). This also removed all Data 360 access from the runtime path, which sidestepped the external-user restriction entirely.

---

## PROJECT 1 — Customer Service Portal Q&A Agent (AS BUILT, COMPLETE)

Customer-facing Agentforce Service Agent on an authenticated Experience Cloud site. Answers questions about the customer's own contract, visits, technician, inspections, and equipment health; answers general how-does-this-work questions from Knowledge; and submits non-urgent service requests as Cases. Verified end-to-end as a real logged-in external user.

### Demo persona

| Field           | Value                                                                                                                                              |
| --------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| Account         | **Highland Tower Holdings** (`ERP-CUST-00032`) — Real Estate, Fort Worth TX                                                                        |
| Site            | Main Facility (`BAS-SITE-00079`), Office Building                                                                                                  |
| Portal user     | **Joshua Martinez**, Facility Manager — `jmartinez36@highlandtowerholdings.com`                                                                    |
| Contract        | `ERP-CTR-00032` — **Gold**, Active, 4 PM/yr, emergency included, 4-hr SLA, ends **2026-10-09**                                                     |
| Next visit      | Quarterly Tune-up on the **Pump**, **2026-08-05**, technician Marcus Johnson                                                                       |
| Last inspection | **VAV Box**, 2026-03-13, Annual Compliance — Fair / Conditional Pass / **Schedule Repair**, inspector Adam Morris                                  |
| Equipment (6)   | `EQ-000780` RTU ✔telemetry · `EQ-000781` VAV ✘ · `EQ-000782` VAV ✘ · `EQ-000783` Pump ✔ · **`EQ-000784` Chiller ✔ health 100** · `EQ-000785` AHU ✔ |

The two VAV boxes have no telemetry → null health score → exercises the "not monitored" path.

### Knowledge (corrects v2)

**v2 claimed 38 loaded articles with placeholder bodies. That was never true — Lightning Knowledge had not been enabled.** Enabled during Project 1 (one-way door; cannot be disabled), admin given the Knowledge User license checkbox.

**Custom fields added to `Knowledge__kav`** (the stock object ships with Title, URL Name, Summary — **no body field**):

- `Article_Body__c` — Rich Text Area (32,768)
- `Category__c` — Picklist: `Customer Portal`, `Contracts`, `Service`, `Reports`, `Security`

Data Categories were deliberately **not** used — a simple picklist plus a retriever filter achieves the same scoping with far less setup at this volume.

**10 articles, authored with real content, published, and Visible to Customer:**

| #   | Title                                                | Category        |
| --- | ---------------------------------------------------- | --------------- |
| 1   | How to Submit a Non-Urgent Service Request           | Customer Portal |
| 2   | Understanding Your Service Contract Coverage Levels  | Contracts       |
| 3   | Preventive Maintenance Visit Schedule and Frequency  | Service         |
| 4   | Emergency Service Response Times by Coverage Level   | Contracts       |
| 5   | How to Read Your Inspection Report                   | Reports         |
| 6   | Reading Your Equipment Health Score                  | Reports         |
| 7   | Reschedule or Cancel a Scheduled Service Visit       | Customer Portal |
| 8   | Technician Identification and Site Access Procedures | Security        |
| 9   | Frequently Asked Questions About PM Visits           | Service         |
| 10  | After-Hours Emergency Contact Procedures             | Service         |

Content is **data-true**: tier numbers, inspection terminology, and health-score bands match the records and the CI formula exactly, so grounded answers never contradict record lookups. Articles cross-reference each other by title.

> **Channel visibility is layout-driven, not part of the publish dialog.** `Visible to Customer` (`IsVisibleInCsp`) and its siblings only appear if added to the Knowledge page layout. Articles published without it are internal-only and invisible to portal users and customer-facing agents. Also: published articles can't be edited in place — Edit creates a new draft version that must be re-published.

### Knowledge grounding — Search Index + Retriever (NOT the Data Library)

| Component             | Detail                                                                                                                                                                                 |
| --------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Search Index          | **`Meridian_KB_Body_Index`** — created manually via Data 360 → Search Index → **Advanced Setup**                                                                                       |
| Source DMO            | `ssot__KnowledgeArticleVersion__dlm`                                                                                                                                                   |
| Chunked field         | **`Article_Body__c` ONLY**                                                                                                                                                             |
| Chunking / embeddings | Passage Extraction / E5 Large V2 (default)                                                                                                                                             |
| Filter field          | `Category__c`                                                                                                                                                                          |
| Chunk DMO             | `Meridian_KB_Body_Index_chunk__dlm`                                                                                                                                                    |
| Retriever             | **`Meridian_KB_Body_Index Retriever`** — returns Chunk + Name + URL; chunks from the chunk DMO, Name/URL hydrated from `ssot__KnowledgeArticleVersion__dlm` (Title→Name, URL Name→URL) |
| Result                | **10 clean chunks, one per article.** Correct article ranks #1 on all probe questions.                                                                                                 |

**The Agentforce Data Library (ADL) low-code path was built, tested, and abandoned.** It auto-chunks multiple Knowledge fields (title, URL name, summary, article number, body), producing thin title-only and metadata-only chunks. A bare title chunk is a near-perfect embedding match for a title-like query ("how do I submit a service request"), so content-free chunks **outranked the real body chunk**. The ADL gives no field-level control — setting "content fields = body only" does nothing. The manual Advanced Setup index has an explicit **Select Fields to Chunk** step, which eliminates the problem. _(Also: ADL reuses an existing search index when a new library has the same identifying fields, so rebuilding via ADL kept returning the same broken chunks.)_ The old ADL and its retriever/index/chunk DMOs were deleted; the Knowledge data stream and `ssot__KnowledgeArticleVersion__dlm` survive independently.

### Prompt template

**`Meridian_Answer_From_Knowledge`** — Flex template, grounded on `Meridian_KB_Body_Index Retriever`, search query bound to the `Question` input, **max results 3**.

Prompt rules: answer only from retrieved chunks; never invent policies, numbers, or dates; decline gracefully and offer escalation if nothing relevant; warm concise customer-facing tone; **reference articles by title and never expose URL-name slugs or internal identifiers**; stay on Meridian topics.

> The question must be written into the prompt **body** (`{!$Input:Question}`), not merely passed as the retriever's search query, or the model may respond that it doesn't see a question.

### Action flows (5) — all account-scoped

Autolaunched Flows, exposed as agent actions. Each returns a plain-text summary for the agent to relay.

| Flow                     | Returns                                                                                       | Notes                                                                                              |
| ------------------------ | --------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------- |
| `Get_Contract_Coverage`  | `CoverageSummary` — tier, type, PM count, emergency, SLA, end date                            | Active contract, most recent `End_Date__c`                                                         |
| `Get_Next_Visit`         | `NextVisitSummary`, `TechnicianName`                                                          | Next `Scheduled` visit ≥ now; **also answers "who is my technician?"** — no separate action needed |
| `Get_Last_Inspection`    | `InspectionSummary` — type, equipment, date, condition, result, recommended action, inspector | Account-wide most recent                                                                           |
| `Get_Equipment_Health`   | `HealthSummary` — score + plain-language band                                                 | Takes `EquipmentTypeRequested`; three paths: score / not-monitored (null) / no such equipment      |
| `Submit_Service_Request` | `ConfirmationMessage`, `CreatedCaseId`                                                        | **Write action.** Creates a Case                                                                   |

**Case creation defaults (hardcoded — the LLM sets none of them):** `AccountId` + `ContactId` from resolved identity, `Subject`/`Description` from the customer, `Origin = Web`, `Status = New`, `Priority = Low`, `Type = Other`. Priority is fixed at Low by design so customer insistence cannot inflate routing; Type is left for human triage because trade classification is not something a customer can self-diagnose.

**Health-score bands** (mirrored in Knowledge article #6): ≥90 "operating normally"; 70–89 "some wear worth keeping an eye on"; <70 "warrants a closer look, may need service."

### Identity and security model ⚠️ (the most important part of this build)

**How identity actually resolves in production — this reverses two earlier assumptions:**

1. **Action flows run as the PORTAL USER (Joshua), not the EinsteinServiceAgent user.** Confirmed via flow debug log (`Current User: Joshua Martinez`). The agent user's permission set is _not_ what powers the action flows.
2. **`@MessagingEndUser.ContactId` is null / Name = "Guest" for authenticated site users.** This is out-of-the-box behavior, not misconfiguration: Messaging for In-App and Web treats web visitors as guests, and the messaging session does **not** inherit the Experience Cloud login. **"Authenticated site user" and "verified messaging user" are separate concepts.** Passing identity into the session would require JWT user verification or pre-chat parameters. _(Credential-based verification on the Embedded Messaging component was attempted and did not populate ContactId in this org.)_ Not needed — the flow self-resolves.

**Three-tier resolution in every action flow** (built defensively in Session 6; tier 2 turned out to be the production path):

```
Tier 1: ContactIdInput   (bound to @variables.ContactId ← @MessagingEndUser.ContactId)
                          → null on this portal, but harmless and future-proof
Tier 2: $User.ContactId   → THE PRODUCTION PATH (flow runs as Joshua)
Tier 3: (removed)         → test fallback, stripped in Session 8
Default: "I couldn't identify your account" → safe refusal
```

Then `Contact.AccountId` → `var_AccountId` → every query filters on it.

**Flows run in "System Context Without Sharing — Access All Data."** Necessary because the portal user's profile has no access to the custom objects (as Joshua, flows threw `sObject type 'Service_Contract__c' is not supported`).

**Chosen deliberately over granting the portal user object access + sharing sets**, because:

- it sidesteps the known Customer Community Plus defect where child records granted via a sharing set on the parent **don't cascade** (the hierarchy here is Account → Site → Equipment → Visits/Inspections);
- the portal user ends up with **zero direct object access** — the only path to data is through account-scoped flows;
- granting broad object access would expose other accounts' data if OWD were ever loosened.

**Interview framing:** _"Portal users have no object access at all. Every retrieval goes through an account-scoped flow running in system context, where the account is derived solely from the authenticated session — so scoping lives in one auditable place instead of being spread across a sharing model."_

> 🔒 **Because there is no sharing layer behind it, the in-flow `ContactId → AccountId` filter IS the entire security boundary.** Consequences:
>
> - `TestAccountId` / `TestContactId` inputs were **removed** in Session 8 — under no-sharing they were a live "set the account, read any account" bypass. **Never reintroduce them.**
> - Any _new_ action flow must derive the account from the session and must never accept an account or contact as an LLM-suppliable input.

### The agent

**`Meridian_Customer_Portal_Assistant`** — Agentforce Service Agent template, new builder. Runs as the auto-provisioned EinsteinServiceAgent user. Built largely by editing **Agent Script** directly (Canvas ↔ Script toggle; Script view is more reliable for bindings and descriptions).

| Subagent               | Role                                                  |
| ---------------------- | ----------------------------------------------------- |
| `agent_router`         | Entry point; classifies and transitions               |
| `GeneralFAQ`           | Knowledge RAG via `Meridian_Answer_From_Knowledge`    |
| `Account_Service_Info` | The 4 read actions                                    |
| `Service_Requests`     | `Submit_Service_Request` (write)                      |
| `escalation`           | Live-agent handoff; doubles as the emergency redirect |
| `off_topic`            | Kept as-is — good prompt-injection guardrails         |

**`ServiceCustomerVerification` was deleted.** Its email-OTP flow exists for _anonymous_ messaging channels; our user is already logged into an authenticated site, so it's redundant friction and painful to demo. The template's native `verified_customer_record_access` feature is **not** used — the flows do their own scoping.

**Action input/output configuration pattern:**

| Input                                                            | Setting                                                                           |
| ---------------------------------------------------------------- | --------------------------------------------------------------------------------- |
| `ContactIdInput`                                                 | bound to `@variables.ContactId`, **`is_user_input: False`**, `is_required: False` |
| `EquipmentTypeRequested`, `RequestSubject`, `RequestDescription` | `is_user_input: True` — the LLM's job                                             |

Summary outputs displayable and unfiltered; `CreatedCaseId` filtered from the agent; `TechnicianName` visible to the agent but not auto-displayed. `Submit_Service_Request` also sets **`require_user_confirmation: True`**.

> `ContactIdInput` is deliberately **not required** — a required-but-empty input causes an opaque platform block instead of the flow's clean "I couldn't identify your account" message. Security comes from the LLM being unable to _set_ it, not from the required flag.

**Equipment-type mapping.** `Get_Equipment_Health` matches the picklist exactly, so `Account_Service_Info`'s instructions list all 12 valid values and instruct the agent to map common phrasing ("my chiller" → `Chiller`, "the rooftop unit"/"my RTU" → `Rooftop Unit (RTU)`) and to **ask rather than guess** on vague wording ("my AC," "the big unit"). A wrong string returns a silent "not found."

**Emergency vs. insistence guardrails (tuned after a real test failure).** Safety hazards (no heating/cooling in a critical space, refrigerant/gas leak, water intrusion, smoke, burning smells) → redirect to the emergency line, **do not write a Case**. But an early test showed "extremely urgent… too hot" over-escalating, so instructions now state explicitly: urgency claims, insistence, and comfort complaints are **not** emergencies — submit normally, don't raise priority, and note that they should call the emergency line if it becomes a safety issue.

### Permissions

**Agent user (`Meridian Customer Portal Assistant` permission set):** object read on Account, Contact, User, Site__c, Service_Contract__c, Equipment_Asset__c, Maintenance_Visit__c, Inspection_Report__c, `Knowledge__kav`; **FLS read on `Article_Body__c` + `Category__c`**; Case Create/Read/Edit; **Run Flows**; **Data Cloud Data Space Management → `default`**; **Prompt Template User** assigned.

- `Knowledge__kav` is the real record object — `KnowledgeArticle` only offers tab visibility.
- Object read **without FLS** yields articles with empty content — a confusing silent failure.
- Without Data Space access the retriever **fails silently at agent runtime** while testing fine as admin.
- "Run Flows" is the blunt instrument; per-flow **Flow Access** is the least-privilege alternative (noted for interviews).

### Experience Cloud deployment chain

Every link is required, and order matters:

```
Omni-Channel enabled
  → Queue: "Meridian Support Fallback" (object = Messaging Session)
  → Routing Configuration
  → Omni-Channel Flow: Route_To_Meridian_Assistant
  → Messaging Channel: "Meridian Portal Channel" (Messaging for In-App and Web)
  → Embedded Service Deployment
  → Embedded Messaging component on the site
  → Publish
```

**Site:** Customer Service template, URL path **`customers`**, activated and published.
**Portal user:** Joshua's Contact enabled as **Customer Community Plus** on the cloned **Meridian Portal Customer** profile. _(The account owner — admin — needed a **role** assigned first; DE gotcha.)_

### Verified on the live portal (as Joshua)

All four reads return correct Highland Tower data; Knowledge answers grounded and slug-free; submit-request confirms before writing and creates a correctly scoped Case (Account = Highland Tower, Contact = Joshua, Origin = Web, Status = New, Priority = Low, Type = Other); emergencies redirect without writing; insistence/discomfort submits normally at Low priority. Router split verified in both directions.

### Deferred (Project 1 v2 candidates)

- **Equipment-specific inspection** — "the last inspection on my _chiller_" (currently account-wide most-recent only).
- **"How's all my equipment?" loop** — iterate the account's units and return a score list.
- Both were deliberately scoped out; the agent asks a clarifying question instead.

---

## LESSONS LEARNED

### Flow

- **Formula fields store 15-character IDs.** `Account__c` on Maintenance_Visit / Inspection_Report / Equipment_Asset is a text formula; filtering it against a real (18-char) Account Id **silently returns nothing**. Normalize with `LEFT({!accountId}, 15)`. The alternative is traversing real lookups (Site → Equipment → Visit), which needs collection/loop handling.
- **Don't rely on `__r` spanning to User.** From an auto-stored Get Records variable, `Technician__r.Name` / `Inspector__r.Name` can return **blank despite a populated Id**, while spanning to a _custom_ object in the same run works fine. Do an explicit **Get Records → User** and reference the variable.
- **Flow's Get Records CANNOT query a Calculated Insight Object.** The object picker _lists_ `*_cio` objects, but saving fails with "not supported" — DMOs only. (A Data Cloud-**Triggered** Flow can _fire on_ a CIO; that's a different mechanism.) Deliver CIO values to Flow via write-back to a CRM field.
- **Data Cloud-Triggered Flows fire on change and do not backfill.** Re-publishing an unchanged CI emits no events. Backfill existing rows separately (Data Loader).
- **Triggered-flow entry conditions offer only comparison operators** — no Is Null. Used `HealthScore__c >= 0`.
- **Editing an active flow creates a new version** — Activate it, or you keep hitting the old version's behavior.
- Use **Date**, not Date/Time, in customer-facing text (`DATEVALUE(...)`) — a raw datetime renders in the _viewer's_ timezone and shifts.
- Text Templates format dates nicely on their own ("October 9, 2026"); parentheses in templates may not render as typed.
- **Debugging trick:** temporarily set an output to `"...DEBUG-" & IF(ISBLANK({!x}), "EMPTY", {!x})` and phrase it like real content so the LLM relays it verbatim; or trace-flag the running user at Flow FINEST.

### Agentforce

- **The router classifies on subagent DESCRIPTIONS only — instructions are never read at routing time.** A detailed routing block written into a subagent's _instructions_ does nothing until the _description_ is updated. This is the single biggest time-sink in agent building.
  - Fix pattern used here: `GeneralFAQ` owns "how does X work / what's included" (and explicitly claims "**how to** submit a request"); `Account_Service_Info` owns "**my** specific record" (possessive); `Service_Requests` owns symptom-led reporting ("making a noise," "isn't working," file it now).
- **Prefer custom actions over the standard query/summarize actions for public-facing agents** (Salesforce's own guidance) — deterministic, scoped, testable.
- **Retriever max-results and the agent action's max-results are separate settings.** Cap context at the action.
- **Never expose URL-name slugs** to customers — instruct the agent to name/link the article.
- The standard `AnswerQuestionsWithKnowledge` action depends on a RAG/Data Library config (`rag_feature_config_id`); if that library is deleted the action silently returns nothing.
- **Builder preview has no messaging session**, so context variables are empty unless pinned via the preview's context-variable setting. If you hardcode a ContactId default for testing, **clear it before deployment**.
- Write actions: set `require_user_confirmation: True` _and_ instruct confirmation. (Watch for double-prompting; if it happens, keep the flag and drop the instruction.)

### Experience Cloud / Messaging

- **Authenticated site user ≠ verified messaging user.** Messaging for In-App and Web treats visitors as guests; `MessagingEndUser.ContactId` is null and Name is "Guest" even for a logged-in portal user. Identity must come from the running user (`$User.ContactId`) or from explicit JWT/pre-chat verification.
- **Action flows run as the portal user**, so the running user's object access governs retrieval — unless the flow runs in system context.
- **Customer Community Plus known defect:** child records granted through a parent via **sharing sets do not cascade**. Design around it (system-context flows) rather than fighting it.
- The **account owner needs a role** before contacts on that account can be enabled as portal users.
- **Omni-Channel Flow requires a Text input variable named `recordId`**, and you must manually pass `{!recordId}` into the Route Work element's Record ID Variable — the platform creates the variable but doesn't wire it. (The Route Work Record ID field may default to the element's own name; fix it.)
- **Republish both the site and the Embedded Service Deployment** after changes; the widget sometimes needs a second publish to appear.
- Enabling **Lightning Knowledge is a one-way door**; the admin also needs the Knowledge User license checkbox.

### Data Cloud CI SQL reference

_(Unchanged from v2 — see that section for the full list: `__dlm`/`__c`/`__cio` suffix rules, no `COALESCE`, `CASE` only inside `SUM`/`COUNT`, no implicit table aliases, ≥1 dimension + ≥1 measure, CIs can read other CIOs, `ssot__` prefixes on standard DMO fields, date-drift caution.)_

---

## BUILD STATUS

**Phase 1 (Data Cloud foundation) — COMPLETE.** Data 360 enabled; 7 bulk CSV streams; DLO→DMO mapping; CRM connector; 8 DMO relationships; Identity Resolution; Equipment Health Score CI.

**Phase 2 — COMPLETE for Projects 1.**

- ✅ `Account_Risk_Score` CI (3 staged CIs) — Project 2 input, verified.
- ✅ **Project 1's retriever** (`Meridian_KB_Body_Index Retriever`) + Knowledge search index.
- ✅ **Equipment Health Score write-back** (was deferred in v2).
- ⏳ **Project 2's retrievers** — unified profile, AR aging, `Account_Risk_Score__cio`. To be built inside Project 2's build conversation.

**Project 1 — ✅ COMPLETE AND LIVE.** Knowledge content, search index, retriever, prompt template, 5 action flows, agent with 6 subagents, portal deployment, verified end-to-end as an external user.

**Project 2 — not started.**

**Phase 3 (Project 3 stretch only) — not started.** Ingestion API connector, Python streaming simulator, Data Action.

---

## Notes for the next agent-building Claude

- **Read the Identity and security model section before touching any flow.** The `ContactId → AccountId` filter is the entire security boundary; flows run system-context/no-sharing. Never add an LLM-suppliable account or contact input.
- **Project 2 is internal/AE-facing**, so its identity model is completely different from Project 1's — internal users have real object access, and scoping is by the AE's book of business, not by a portal session. Don't copy Project 1's system-context pattern without re-thinking it.
- Project 2 grounds on `Account_Risk_Score__cio` (dimension = ERP customer id, **higher = more risk**). Since Flow cannot query a CIO, expect the same decision point: write-back to a CRM field vs. Apex/Query API. Project 1 chose write-back; a CIO write-back pattern now exists to copy (`Sync_Health_Score_To_CRM`).
- 9 Service Contracts are in "Pending Renewal" — Project 2's demo targets, with richer maintenance history.
- Only 1 technician (Marcus Johnson) across all 500 visits; 1 inspector (Adam Morris).
- **Delete portal test Cases** — they inflate `Account_Case_Aggregates` and skew `Account_Risk_Score__cio`.
- Knowledge currently holds **10 real customer-facing articles** (v2's "38 with placeholder bodies" was never built). Project 2 may want internal-facing articles; those need `Visible In Internal App` and probably a separate Category value.
- Retrievers and segments should target the **Unified** DMOs.
- Org is near its 5MB CRM storage limit (~4.4MB). Data 360 storage is separate, but CRM write-backs consume CRM storage.
