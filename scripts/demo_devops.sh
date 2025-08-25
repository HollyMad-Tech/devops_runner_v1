#!/usr/bin/env bash
set -euo pipefail
[ -f .env ] && set -a && . ./.env && set +a
BASE="http://localhost:${PORT:-8765}"
need(){ command -v "$1" >/dev/null 2>&1 || { echo "missing: $1"; exit 1; }; }
need curl; need jq; need sha256sum || need shasum
curl -fsS "$BASE/health" >/dev/null
PLAN=$(curl -fsS -X POST "$BASE/plan" -H 'content-type: application/json' -d '{"workflow":"devops_patch","ticket":"DEV-125","repo":"fixtures/local_repo","branch":"main","dry_run":true}')
PID=$(jq -r .id <<<"$PLAN")
RUN=$(curl -fsS -X POST "$BASE/exec" -H 'content-type: application/json' -d "{\"plan_id\":\"$PID\"}")
CID=$(jq -r .artifacts.commit_id <<<"$RUN"); AUD=$(jq -r .artifacts.audit_zip <<<"$RUN")
if command -v sha256sum >/dev/null; then SUM=$(sha256sum "$AUD"|awk '{print $1}'); else SUM=$(shasum -a 256 "$AUD"|awk '{print $1}'); fi
echo "KPI SUMMARY"; jq -r '.artifacts.kpis|to_entries[]|"\(.key)=\(.value)"' <<<"$RUN"
echo "Commit: $CID"; echo "Audit.zip: $AUD (sha256 $SUM)"