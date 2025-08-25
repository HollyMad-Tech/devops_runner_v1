#!/usr/bin/env pwsh
$ErrorActionPreference="Stop"
if (Test-Path .env) { Get-Content .env | ? {$_ -notmatch "^(#|\s*$)"} | % { $k,$v=$_.Split("="); set-item env:$k $v } }
$PORT = ${env:PORT}; if (-not $PORT) { $PORT = 8765 }
$BASE = "http://localhost:$PORT"
(Invoke-WebRequest "$BASE/health" -UseBasicParsing).StatusCode | Out-Null
$PLAN_JSON = '{"workflow":"research_brief","depth":"deep","topic":"Pilot readiness of SENA v0.2.0"}'
$sw=[Diagnostics.Stopwatch]::StartNew(); $PLAN = & curl.exe -fsS -X POST "$BASE/plan" -H "Content-Type: application/json" -d $PLAN_JSON; $sw.Stop()
$TTFT_S=[math]::Round($sw.Elapsed.TotalSeconds,3)
$hasJq = (Get-Command jq -ErrorAction SilentlyContinue) -ne $null
if ($hasJq) { $PlanId = ($PLAN | jq -r ".id") } else { $PlanId = (ConvertFrom-Json $PLAN).id }
$RUN = & curl.exe -fsS -X POST "$BASE/exec" -H "Content-Type: application/json" -d "{`"plan_id`":`"$PlanId`"}"
if ($hasJq) {
  $PDF = ($RUN | jq -r ".artifacts.exports.pdf"); $MD = ($RUN | jq -r ".artifacts.exports.md"); $HTML = ($RUN | jq -r ".artifacts.exports.html")
  $AUD = ($RUN | jq -r ".artifacts.audit_zip")
  $PLAN_ADH = ($RUN | jq -r ".artifacts.kpis.plan_adherence"); $TOOL_SUC = ($RUN | jq -r ".artifacts.kpis.tool_success")
  $P95_DRY = ($RUN | jq -r ".artifacts.kpis.p95_s.dry"); $P95_RUN = ($RUN | jq -r ".artifacts.kpis.p95_s.run_tests")
  $RB_HALL = ($RUN | jq -r ".artifacts.kpis.rb_hard_halluc")
} else {
  $obj = ConvertFrom-Json $RUN
  $PDF = $obj.artifacts.exports.pdf; $MD = $obj.artifacts.exports.md; $HTML = $obj.artifacts.exports.html
  $AUD = $obj.artifacts.audit_zip
  $PLAN_ADH = $obj.artifacts.kpis.plan_adherence; $TOOL_SUC = $obj.artifacts.kpis.tool_success
  $P95_DRY = $obj.artifacts.kpis.p95_s.dry; $P95_RUN = $obj.artifacts.kpis.p95_s.run_tests
  $RB_HALL = $obj.artifacts.kpis.rb_hard_halluc
}
$Checksum = (Get-FileHash -LiteralPath $AUD -Algorithm SHA256).Hash.ToLower()
"KPI SUMMARY"
"TTFT=$TTFT_S s"; "p95(dry)=$P95_DRY s"; "p95(run+tests)=$P95_RUN s"
"Plan-Adherence=$PLAN_ADH"; "Tool-Success=$TOOL_SUC"; "RB hard claims Hallucination=$RB_HALL"
"Audit.zip: $AUD"; "Checksum:  $Checksum"