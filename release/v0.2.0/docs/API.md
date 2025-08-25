# API — Contracts (v0.2.0)

## POST /plan
- Request (RB example):
```json
{
  "workflow":"research_brief",
  "depth":"deep",
  "topic":"<user goal prompt>",
  "requirements":{"evidence_domains_per_hard_claim":3,"counterarguments":2,"risk_score":true}
}
Write-NoBom -Path "docs/API.md" -LF -Content @'
# API — Contracts (v0.2.0)

## `POST /plan`
- **Purpose:** Produce a structured plan for a workflow.

- **Request (RB example):**
```json
{
  "workflow": "research_brief",
  "depth": "deep",
  "topic": "<user goal prompt>",
  "requirements": {
    "evidence_domains_per_hard_claim": 3,
    "counterarguments": 2,
    "risk_score": true
  }
}