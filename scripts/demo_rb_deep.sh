#!/usr/bin/env bash
set -euo pipefail
[ -f .env ] && set -a && . ./.env && set +a
BASE="http://localhost:${PORT:-8765}"
need(){ command -v "$1" >/dev/null 2>&1 || { echo "missing: $1"; exit 1; }; }
need curl; need jq; need sha256sum || need shasum
curl -fsS "$BASE/health" >/dev/null
PLAN_JSON=$(jq -n '{workflow:"research_brief", depth:"deep", topic:"Pilot readiness of SENA v0.2.0"}')
T0=$(date +%s%3N); PLAN=$(curl -fsS -X POST "$BASE/plan" -H 'content-type: application/json' -d "$PLAN_JSON"); TTFT_MS=$(( $(date +%s%3N) - T0 ))
PID=$(jq -r .id <<<"$PLAN")
RUN=$(curl -fsS -X POST "$BASE/exec" -H 'content-type: application/json' -d "{\"plan_id\":\"$PID\"}")
PDF=$(jq -r .artifacts.exports.pdf <<<"$RUN"); MD=$(jq -r .artifacts.exports.md <<<"$RUN"); HTML=$(jq -r .artifacts.exports.html <<<"$RUN")
AUD=$(jq -r .artifacts.audit_zip <<<"$RUN")
if command -v sha256sum >/dev/null; then SUM=$(sha256sum "$AUD"|awk '{print $1}'); else SUM=$(shasum -a 256 "$AUD"|awk '{print $1}'); fi
PLAN_ADH=$(jq -r .artifacts.kpis.plan_adherence <<<"$RUN"); TOOL_SUC=$(jq -r .artifacts.kpis.tool_success <<<"$RUN")
P95_DRY=$(jq -r .artifacts.kpis.p95_s.dry <<<"$RUN"); P95_RUN=$(jq -r .artifacts.kpis.p95_s.run_tests <<<"$RUN")
RB_HALL=$(jq -r .artifacts.kpis.rb_hard_halluc <<<"$RUN")
TTFT_S=$(python - <<PY
print(int("$TTFT_MS")/1000)
PY
)
echo "KPI SUMMARY"
echo "TTFT=${TTFT_S}s"; echo "p95(dry)=${P95_DRY}s"; echo "p95(run+tests)=${P95_RUN}s"
echo "Plan-Adherence=${PLAN_ADH}"; echo "Tool-Success=${TOOL_SUC}"; echo "RB hard claims Hallucination=${RB_HALL}"
echo "Audit.zip: $AUD"; echo "Checksum: $SUM"