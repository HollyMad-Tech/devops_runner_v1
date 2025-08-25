# Demo — Research Brief (depth=deep)

## Steps
1) POST /plan (`workflow=research_brief`, `depth=deep`)
2) POST /exec (`plan_id`)
3) Validate outputs:
   - Background → Current → Options → Risks → Recommendation
   - ≥3 unique domains per hard claim
   - ≥2 counterarguments + risk score
   - Δ-brief vs last run (≥3 changes)
   - Exports: PDF/MD/HTML + Audit.zip (checksum logged)
4) Print KPI summary & assert thresholds

Artifacts: `${EXPORTS_DIR}` (exports), `${AUDIT_DIR}` (audits)