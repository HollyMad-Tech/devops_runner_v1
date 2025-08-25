#!/usr/bin/env pwsh
$ErrorActionPreference="Stop"
if (Test-Path .env) { Get-Content .env | ? {$_ -notmatch "^(#|\s*$)"} | % { $k,$v=$_.Split("="); set-item env:$k $v } }
$PORT = ${env:PORT}; if (-not $PORT) { $PORT = 8765 }
$BASE = "http://localhost:$PORT"
(Invoke-WebRequest "$BASE/health" -UseBasicParsing).StatusCode | Out-Null
$PLAN = & curl.exe -fsS -X POST "$BASE/plan" -H "Content-Type: application/json" -d '{"workflow":"devops_patch","ticket":"DEV-125","repo":"fixtures/local_repo","branch":"main","dry_run":true}'
$hasJq = (Get-Command jq -ErrorAction SilentlyContinue) -ne $null
if ($hasJq) { $PlanId = ($PLAN | jq -r ".id") } else { $PlanId = (ConvertFrom-Json $PLAN).id }
$RUN = & curl.exe -fsS -X POST "$BASE/exec" -H "Content-Type: application/json" -d "{`"plan_id`":`"$PlanId`"}"
if ($hasJq) {
  $CID = ($RUN | jq -r ".artifacts.commit_id"); $AUD = ($RUN | jq -r ".artifacts.audit_zip")
  $TTFT = ($RUN | jq -r ".artifacts.kpis.ttft_s"); $P95D = ($RUN | jq -r ".artifacts.kpis.p95_s.dry")
  $P95R = ($RUN | jq -r ".artifacts.kpis.p95_s.run_tests"); $PADH = ($RUN | jq -r ".artifacts.kpis.plan_adherence"); $TSUC = ($RUN | jq -r ".artifacts.kpis.tool_success")
} else {
  $obj = ConvertFrom-Json $RUN
  $CID = $obj.artifacts.commit_id; $AUD = $obj.artifacts.audit_zip
  $TTFT = $obj.artifacts.kpis.ttft_s; $P95D = $obj.artifacts.kpis.p95_s.dry
  $P95R = $obj.artifacts.kpis.p95_s.run_tests; $PADH = $obj.artifacts.kpis.plan_adherence; $TSUC = $obj.artifacts.kpis.tool_success
}
"KPI SUMMARY"; "TTFT=$TTFT s"; "p95(dry)=$P95D s"; "p95(run+tests)=$P95R s"; "Plan-Adherence=$PADH"; "Tool-Success=$TSUC"
"Commit: $CID"; "Audit.zip: $AUD (sha256 " + (Get-FileHash -LiteralPath $AUD -Algorithm SHA256).Hash.ToLower() + ")"