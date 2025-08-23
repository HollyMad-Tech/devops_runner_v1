#!/usr/bin/env bash
set -euo pipefail
LOG_DIR="artifacts/logs/canary"
METRICS_DIR="artifacts/metrics"
mkdir -p "$LOG_DIR" "$METRICS_DIR"
STRICT="${CI_STRICT:-false}"
CASES="${1:-canaries/cases.jsonl}"
echo "==> Canary suite (STRICT=${STRICT})" | tee "${LOG_DIR}/canary.out"
if [ -f "${CASES}" ]; then
  echo "Using canary set: ${CASES}" | tee -a "${LOG_DIR}/canary.out"
  python ci/scripts/run_canaries.py --jsonl "${CASES}" --out "${METRICS_DIR}/canary_metrics.jsonl" 2>&1 | tee -a "${LOG_DIR}/canary_run.out"
else
  echo "No canary JSONL found at ${CASES}." | tee -a "${LOG_DIR}/canary.out"
  if [ "$STRICT" = "true" ]; then echo "STRICT=true -> failing due to missing canaries." | tee -a "${LOG_DIR}/canary.out"; exit 1; fi
  : > "${METRICS_DIR}/canary_metrics.jsonl"
fi
echo "Canary suite completed." | tee -a "${LOG_DIR}/canary.out"
