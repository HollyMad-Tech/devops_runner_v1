# SENA (Pilot v0.2.0)

*Purpose.* Run two **hero workflows** locally: (1) **Research Brief (deep)** with evidence, counterarguments, Δ-brief & exports; (2) **DevOps Patch** from dry-run → run → tests → commit & Audit.zip. KPIs print at the end.

## Quickstart (≤10 lines)
1. Install Docker Desktop (enable WSL2 on Windows).
2. `cp .env.example .env`
3. `docker compose up --build -d`
4. Health: `curl -fsS localhost:8765/health` → `200`.
5. RB demo: `./scripts/demo_rb_deep.sh` (or `.ps1` on Windows).
6. DevOps demo: `./scripts/demo_devops.sh` (or `.ps1`).
7. Artifacts: `workspace/exports/` (exports), `workspace/audit/` (audits).
8. KPIs print at demo end (thresholds in `.env`).