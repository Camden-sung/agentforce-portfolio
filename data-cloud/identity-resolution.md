# Identity Resolution

Scaffolded from `docs/meridian_schema_reference_v3.md`. Data Cloud Identity
Resolution rulesets have poor Metadata API coverage and can't be read from
the org via retrieve, so this is a hand-maintained summary, not a
retrieved/generated artifact.

## As-built (per schema reference v3)

| Field        | Value                                                                       |
| ------------ | --------------------------------------------------------------------------- |
| Ruleset name | `Customer_Identity_Resolution`                                              |
| ID           | `INDV`                                                                      |
| Primary DMO  | Individual                                                                  |
| Match rule   | Single rule: **Email Exact**, via Contact Point Email                       |
| Outputs      | Unified Individual (152 records), Unified Contact Point Email (152 records) |

Downstream retrievers and segments should target the **Unified** DMOs, not
the raw source DMOs.

## TODO — not stated in the reference doc

- Exact match rule configuration (blocking keys, fuzzy-match settings, if any
  beyond the single Email Exact rule)
- Reconciliation rule / survivorship logic for conflicting field values
- Which DMOs besides Individual and Contact Point Email participate in the
  ruleset (e.g. whether Contact or Account feed into it directly)
- Whether any additional match rules were evaluated and rejected during the
  build (the doc states only the one rule that was kept)

These should be confirmed by opening the ruleset in Data Cloud > Identity
Resolution rather than assumed from this summary.
