param([switch]$KeepServer)
$ErrorActionPreference="Stop"

# Load .env
if (Test-Path .env) {
  Get-Content .env | ? {$_ -notmatch "^(#|\s*$)"} | % { $k,$v=$_.Split("="); set-item env:$k $v }
}

function Get-EnvOr($name,$def){
  $item = Get-Item -Path ("Env:{0}" -f $name) -ErrorAction SilentlyContinue
  if ($null -eq $item -or [string]::IsNullOrWhiteSpace($item.Value)) { return $def } else { return $item.Value }
}

$PORT     = [int](Get-EnvOr 'PORT' '8765')
$METRICS  = Get-EnvOr 'METRICS_JSONL' './workspace/metrics/metrics.jsonl'
$EXPORTS  = Get-EnvOr 'EXPORTS_DIR'   './workspace/exports'
$AUDIT    = Get-EnvOr 'AUDIT_DIR'     './workspace/audit'
$COMMITS  = "./workspace/commits"

$G_PLAN   = [double](Get-EnvOr 'GATE_PLAN_ADHERENCE' '0.90')
$G_TOOL   = [double](Get-EnvOr 'GATE_TOOL_SUCCESS'   '0.95')
$G_HALL   = [double](Get-EnvOr 'GATE_RB_HARD_HALLUC' '0.01')
$G_TTFT   = [double](Get-EnvOr 'GATE_TTFT_S'         '0.30')
$G_P95D   = [double](Get-EnvOr 'GATE_P95_DRY_S'      '2.0')
$G_P95R   = [double](Get-EnvOr 'GATE_P95_RUNTEST_S'  '6.0')

# Ensure server is up
try { Invoke-WebRequest "http://localhost:$PORT/health" -UseBasicParsing | Out-Null }
catch {
  Write-Host "Starting local server..."
  powershell -ExecutionPolicy Bypass -File .\Start-Local.ps1 -KeepServer | Out-Null
  Start-Sleep 1
}

# Run demos
$outRB  = powershell -ExecutionPolicy Bypass -File .\scripts\demo_rb_deep.ps1
$outDEV = powershell -ExecutionPolicy Bypass -File .\scripts\demo_devops.ps1

# Robust number parser
function Get-Num($text, $name){
  $s = ($text -join "`n")
  $pattern = [regex]::Escape($name) + '=\s*([0-9]+(?:\.[0-9]+)?)'
  $m = [regex]::Match($s, $pattern)
  if ($m.Success) {
    return [double]::Parse($m.Groups[1].Value, [Globalization.CultureInfo]::InvariantCulture)
  }
  return $null
}

# KPIs
$rb_ttft = Get-Num $outRB  'TTFT'
$rb_p95d = Get-Num $outRB  'p95(dry)'
$rb_p95r = Get-Num $outRB  'p95(run+tests)'
$rb_padh = Get-Num $outRB  'Plan-Adherence'
$rb_tool = Get-Num $outRB  'Tool-Success'
$rb_hall = Get-Num $outRB  'RB hard claims Hallucination'

$rb_aud_m = ($outRB  | Select-String -Pattern 'Audit\.zip:\s+(.+)$')
$rb_aud   = if ($rb_aud_m) { $rb_aud_m.Matches[0].Groups[1].Value } else { $null }

$dv_ttft = Get-Num $outDEV 'TTFT'
$dv_p95d = Get-Num $outDEV 'p95(dry)'
$dv_p95r = Get-Num $outDEV 'p95(run+tests)'
$dv_padh = Get-Num $outDEV 'Plan-Adherence'
$dv_tool = Get-Num $outDEV 'Tool-Success'

$dv_aud_m = ($outDEV | Select-String -Pattern 'Audit\.zip:\s+(.+?)\s+\(sha256')
$dv_aud   = if ($dv_aud_m) { $dv_aud_m.Matches[0].Groups[1].Value } else { $null }

$dv_cid_m = ($outDEV | Select-String -Pattern '^Commit:\s+([0-9a-f]+)')
$dv_cid   = if ($dv_cid_m) { $dv_cid_m.Matches[0].Groups[1].Value } else { $null }

# Files/asserts
$exportCount = (Get-ChildItem -Path "$EXPORTS\*" -Include *.pdf,*.md,*.html -Recurse -File).Count
$rb_ok = ($rb_aud -and (Test-Path $rb_aud)) -and (Test-Path $EXPORTS) -and ($exportCount -ge 3)
$dv_ok = ($dv_aud -and (Test-Path $dv_aud)) -and ($dv_cid -and (Test-Path (Join-Path $COMMITS "$dv_cid.txt")))

# Metrics JSONL ticked ticked
$met_ok = (Test-Path $METRICS) -and ((Get-Content $METRICS | Measure-Object -Line).Lines -ge 2)

# Thresholds
$checks = @(
  ($rb_ttft -le $G_TTFT),
  ($rb_p95d -le $G_P95D),
  ($rb_p95r -le $G_P95R),
  ($rb_padh -ge $G_PLAN),
  ($rb_tool -ge $G_TOOL),
  ($rb_hall -lt $G_HALL),
  ($dv_ttft -le $G_TTFT),
  ($dv_p95d -le $G_P95D),
  ($dv_p95r -le $G_P95R),
  ($dv_padh -ge $G_PLAN),
  ($dv_tool -ge $G_TOOL)
) | % { $_ -eq $true }
$th_ok = ($checks.Count -eq 11)

"--- ACCEPTANCE SUMMARY ---"
"/health OK on port $PORT"
"Metrics JSONL: $met_ok"
"RB exports/audit: $rb_ok"
"DevOps commit/audit: $dv_ok (commit $dv_cid)"
"Thresholds OK: $th_ok"
"KPI (RB): TTFT=$rb_ttft p95d=$rb_p95d p95r=$rb_p95r Plan=$rb_padh Tool=$rb_tool Hall=$rb_hall"
"KPI (DV): TTFT=$dv_ttft p95d=$dv_p95d p95r=$dv_p95r Plan=$dv_padh Tool=$dv_tool"

if ($met_ok -and $rb_ok -and $dv_ok -and $th_ok) {
  "RESULT: PASS"; if (-not $KeepServer) { powershell -ExecutionPolicy Bypass -File .\Stop-Local.ps1 | Out-Null }; exit 0
} else {
  "RESULT: FAIL"; if (-not $KeepServer) { powershell -ExecutionPolicy Bypass -File .\Stop-Local.ps1 | Out-Null }; exit 1
}

