# RUNBOOK — Install / Operate / Troubleshoot (v0.2.0)

## Prereqs
- Docker Desktop (WSL2 on Windows), Git, curl.
- Copy config: `cp .env.example .env`.

## Up/Down
- Up: `docker compose up --build -d`
- Logs: `docker compose logs -f sena`
- Down: `docker compose down`

## Health & Metrics
- `GET /health` → `200`.
- Metrics JSONL: `${METRICS_JSONL}` (default `workspace/metrics/metrics.jsonl`).
- Log rotation: `${LOG_DIR}/${LOG_FILE}`, max `${LOG_MAX}`, keep `${LOG_BACKUPS}`.

## KPIs / Timings
- Demos compute: **TTFT**, **p95** timings, **Plan-Adherence**, **Tool-Success**, **RB Hard-Claim Halluc (<1%)**.
- Low-level timings: `GET /debug/timings` (impl-dependent).

## Audit Bundle & Replay
- Each demo writes `${AUDIT_DIR}/<timestamp>_<kind>/Audit.zip` and prints **SHA256**.
- Replay example: `python -m runtime.audit --last --root ${AUDIT_DIR}`.

## CI Gates
- `docs.yml`: markdown lint + link check.
- `demo_smoke.yml`: runs both demos in CI, asserts KPI thresholds, uploads exports + audits.

## Common Errors
- **Port in use** → change `PORT`.
- **Windows EOL/BOM** → use LF for `*.sh`; no BOM.
- **WSL path** → run shell demos in WSL Ubuntu.

## Security
- Default-deny tool policies, human sign-off; see `docs/SECURITY.md`.