# Schema Reference v3 — Addendum / v4 Input

Cross-checked v3 against all nine project conversations. Findings below, ordered
by how much they'd cost you if missed.

**Provenance note:** where a step was walked through but you never explicitly
confirmed completion, it's marked ⚠️ **VERIFY**. Don't fold those into v4 as
as-built until you've checked the org.

---

## 🔴 A. The entire portal polish session is missing from v3

This is the big one. **v3 was written _before_ the portal polish work.** The
sequence in the Project 1 conversation was: v3 generated → you said "the site is
pretty bare bones" → a whole additional scope of work happened → you moved to
Project 2. None of it made it into any doc.

What was built after v3 was frozen:

| Item                | Detail                                                                                                                                                  |
| ------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Components deleted  | Discussions, My Feed, Ask a Question, Trending Articles, Trending Topics — the Chatter-community cruft whose empty states made the site read unfinished |
| Theme / branding    | Colors set to a Meridian palette, logo uploaded, site name set                                                                                          |
| Home page rebuilt   | **3 HTML Editor components**: hero banner, 4-tile row, Help Articles link list                                                                          |
| Nav                 | Trimmed to Home (+ Knowledge); App Launcher hidden if it exposed internal objects                                                                       |
| Article URL pattern | `/customers/article/<URL-Name>` on the Customer Service template                                                                                        |
| Tile CSS            | `flex: 1 1 220px` — row on desktop, stacks on mobile                                                                                                    |

**Hex palette actually used in the portal HTML:** `#1b3a5c` (primary),
`#2d5f8a` (gradient end), `#dfe3e8` (borders), `#5a6570` (body text).

**Known caveat worth documenting:** Experience Builder sanitizes markup, and the
Aura-based Rich Content Editor is more aggressive than the HTML Editor — it can
strip inline styles and flatten flex layout. Fallback was separate Tile/Rich
Content components in a multi-column section.

**Design decision that belongs in v4 and in the README:**

> The portal is intentionally a thin branded shell. The agent _is_ the
> self-service layer — a conversational-first portal where the assistant
> replaces click-through navigation. Record-list components are deliberately
> absent because the portal user has no object access by design.

That's a better demo narrative than a half-populated record portal, and it
explains an otherwise odd-looking site to anyone reviewing it.

---

## 🔴 B. v3's "zero object access" claim is now inaccurate

v3 states, twice, and uses it as the headline interview line:

> "the portal user ends up with **zero direct object access** — the only path to
> data is through account-scoped flows"

The polish session granted the **Meridian Portal Customer** profile:

- Object **read on `Knowledge__kav`**
- **FLS read on `Article_Body__c` and `Category__c`**

⚠️ **VERIFY** — you asked for this walkthrough and it was given, but you never
confirmed you finished it. Check the profile before treating it as as-built.

If you did grant it, the interview framing needs amending, and the amendment is
_stronger_ than the original because it shows you reasoned about the exception
rather than applying a blanket rule:

> "Portal users have no access to any account-scoped object — contracts,
> equipment, visits, inspections all route through account-scoped flows in
> system context. The one direct grant is Knowledge, which is deliberately
> non-account-specific: the same ten articles for every customer, so there's
> nothing to scope and no sharing model to get wrong."

Getting caught by an interviewer on a "zero access" claim that isn't literally
true is a bad outcome. Fix the wording.

---

## 🟠 C. The logo is an org asset with no home in the doc or repo

A separate conversation produced a Meridian Building Solutions logo — SVG plus
PNG variants at 600×120, 1200×240, and a tight-cropped 2×.

**Logo palette:** `#1e4d7b` → `#0f2847` (icon gradient), `#d4a548` → `#b88a32`
(gold accent), `#0f2847` wordmark, `#3d4a5c` subtitle.

Two things:

1. ⚠️ **VERIFY** whether it was actually uploaded to the org (Setup → Company
   Information, and/or the Experience Cloud theme panel). Creating it and
   uploading it were separate conversations.
2. **Palette mismatch.** The logo uses `#1e4d7b`/`#0f2847`; the portal hero uses
   `#1b3a5c`/`#2d5f8a`. Close but not the same. Nobody will die, but if a
   screenshot of the portal goes in your README next to the logo, pick one.

**For the repo:** if uploaded, it lives as a `ContentAsset` or `StaticResource`
and should be in a manifest. Also just commit the SVG to `docs/assets/` directly
— it's yours, and it's the kind of thing that makes a repo look finished.

---

## 🟠 D. Data Cloud detail that v3 abbreviated away

v3 says "_Abbreviated; see v2 for full DLO/DMO field mapping detail._" That's a
problem now, because v2 is superseded and nobody reads two docs. Several of
these were explicit mid-build corrections that cost you time to learn — losing
them means relearning them.

**The CRM connector brought in exactly 5 objects**, not all of them:

> Account, Contact, Case, `Equipment_Asset__c`, `Service_Contract__c`.
> **Site, Maintenance_Visit, and Inspection_Report were deliberately deferred** —
> nothing in either Calculated Insight needed them, and fewer objects meant a
> cleaner Identity Resolution screen.

v3 never says this. Someone reading it would assume all custom objects are in
Data Cloud. They aren't, and that constrains what Project 2's retrievers can do.

**Custom DMO inventory** (v3 gives DLO names but not the DMO names/keys):

| DLO                   | DMO                            | Category   | Primary Key       | Event Time        |
| --------------------- | ------------------------------ | ---------- | ----------------- | ----------------- |
| `ERP_AR_Aging`        | `ERP_AR_Aging_DMO__dlm`        | Other      | `erp_customer_id` | —                 |
| `ERP_Invoices`        | `ERP_Invoices_DMO__dlm`        | Other      | `invoice_id`      | —                 |
| `ERP_Parts_Inventory` | `ERP_Parts_Inventory_DMO__dlm` | Other      | `part_number`     | —                 |
| `Portal_Engagement`   | `Portal_Engagement_DMO__dlm`   | Engagement | `event_id`        | `event_timestamp` |
| `CSR_Call_Log`        | `CSR_Call_Log_DMO__dlm`        | Engagement | `call_id`         | `call_timestamp`  |
| `Equipment_Telemetry` | `Equipment_Telemetry_DMO__dlm` | Engagement | `reading_id`      | `reading_date`    |
| `Equipment_Fault`     | `Equipment_Fault_DMO__dlm`     | Engagement | `fault_event_id`  | `occurred_at`     |

**Corrections learned during the build that aren't in v3:**

- **Event Time Field is set at the data stream / DLO level, not on the DMO.**
  The custom DMO only needs category = Engagement. This was explicitly corrected
  mid-session after you couldn't find the setting — exactly the kind of thing
  that wastes an hour the second time.
- **Data Cloud DLO field types include Boolean** (Text / Number / Date /
  Date-Time / Boolean). `resolved_on_first_contact` and `still_active` both
  auto-detected correctly.
- **The CRM connector's `_Home` suffix is convention, not a mistake** — leave it
  alone. v3 mentions the suffix but not the "don't fight it" guidance.
- **Nothing auto-mapped to standard DMOs in your org** — you mapped all five CRM
  objects manually. Worth noting since guides assume auto-mapping.
- `External_ERP_Customer_Id__c` had to be manually mapped onto the Account DMO;
  it's the ERP join key and Identity Resolution silently breaks without it.

**The 8 DMO relationships are never enumerated.** v3 says "13 DMOs and 8
Relationships" and stops. Project 2 will need to know which joins exist. List
them in v4.

---

## 🟡 E. The Knowledge data stream is missing from the source table

v3's source table lists **7 CSVs**. But the Knowledge Data 360 stream and
`ssot__KnowledgeArikleVersion__dlm` are referenced elsewhere in v3 as surviving
the ADL deletion. So the actual stream count is:

> 7 CSV streams + CRM connector (5 objects) + 1 Knowledge stream

The table should say so, or the counts won't reconcile for anyone auditing it.

---

## 🟡 F. Easy-to-miss items — built or planned, no home anywhere

**Never built, previously flagged, still worth considering:**

- **Agent test set / Agentforce Testing Center.** Your testing to date is ad hoc.
  A utterance→expected-topic→expected-action test set is a genuine skill gap
  _and_ a portfolio differentiator — almost nobody's demo agents have evals
  attached. Summer '26 added `aiAgentScorerDefinitions` to the Metadata API, so
  custom scorers can live in source control, which makes this repo-visible work.
- **One real REST callout** via Named Credentials + External Services. Raised in
  conversation 1 as the single integration worth doing, deferred to Project 2/3,
  never done. Still the cheapest way to prove external-integration mechanics.
- **Org branding** — Setup → Company Information name + logo, separate from the
  Experience Cloud theme.

**Outstanding TODO already in v3 but still not done:**

- 🔴 **Delete the portal test Cases.** They inflate `Account_Case_Aggregates` and
  skew `Account_Risk_Score__cio` — which is Project 2's _primary signal_. Do
  this before Project 2 touches anything, or you'll debug a risk score that's
  wrong for a reason you already documented.

---

## Metadata types to add to the manifests

Based on the above, add to `package-experience.xml`:

```xml
<types>
    <members>*</members>
    <name>ContentAsset</name>
</types>
<types>
    <members>*</members>
    <name>StaticResource</name>
</types>
<types>
    <members>*</members>
    <name>Audience</name>
</types>
<types>
    <members>*</members>
    <name>NetworkBranding</name>
</types>
```

The hero/tiles/article HTML lives inside `ExperienceBundle`, which is already in
that manifest — so the portal design work _will_ come down, as long as you
publish the site before retrieving.

---

## Suggested v4 changelog line

> **Changes from v3:** portal polish session documented (branding, home page
> rebuild, deleted Chatter components, article URL pattern); "zero object
> access" corrected to reflect the Knowledge read grant and its rationale; CRM
> connector object list made explicit (5 of 8 objects; Site/MV/IR deferred);
> custom DMO names, primary keys, and event-time fields tabulated; Event Time
> Field level corrected to DLO; Boolean added to DLO field types; Knowledge
> stream added to the source table; logo asset recorded.
