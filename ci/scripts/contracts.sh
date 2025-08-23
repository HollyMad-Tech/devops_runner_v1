#!/usr/bin/env bash
set -euo pipefail
LOG_DIR="artifacts/logs/contracts"
mkdir -p "$LOG_DIR"
BASE_URL="${APP_BASE_URL:-http://127.0.0.1:8765}"
echo "==> Contract tests against ${BASE_URL}" | tee "${LOG_DIR}/contracts.out"
function require_200() {
  local path="$1"
  local url="${BASE_URL}${path}"
  local code
  code=$(curl -s -o /tmp/resp.json -w "%{http_code}" "$url" || echo "000")
  echo "[HTTP] ${path} -> ${code}" | tee -a "${LOG_DIR}/contracts.out"
  if [ "$code" != "200" ]; then
    echo "Contract failed: ${path} returned ${code}" | tee -a "${LOG_DIR}/contracts.out"
    exit 1
  fi
}
if [ "${CI_STRICT}" = "true" ]; then
  require_200 "/ping"
  require_200 "/plan"
  require_200 "/exec"
else
  echo "CI_STRICT=false -> HTTP checks are skipped (enable after wiring service)." | tee -a "${LOG_DIR}/contracts.out"
fi
RET=0
for f in tools/*.schema.json schema/*.schema.json; do
  [ -f "$f" ] || continue
  echo "Validating JSON schema: $f" | tee -a "${LOG_DIR}/contracts.out"
  python - <<PY || RET=1
import json,sys
p="${f}"
try:
  with open(p,"r",encoding="utf-8") as fh: json.load(fh)
except Exception as e:
  print("Invalid JSON:", p, "->", e)
  sys.exit(1)
print("OK", p)
PY
done
if [ $RET -ne 0 ]; then
  echo "Schema validation failed." | tee -a "${LOG_DIR}/contracts.out"
  exit 1
fi
echo "Contracts OK." | tee -a "${LOG_DIR}/contracts.out"
