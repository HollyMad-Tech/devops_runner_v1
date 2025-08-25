# Demo — DevOps Patch

Flow:
1) Ticket → POST /plan (`workflow=devops_patch`)
2) Dry-run → run
3) Tests pass; auto-commit created (print id)
4) Commit rationale includes: Problem / Approach / Tests / Risks
5) Audit.zip generated and path printed
6) KPI summary printed and thresholds asserted