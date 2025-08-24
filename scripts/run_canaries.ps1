param([switch]$Ci)

function Remove-BomInFile {
  param([Parameter(Mandatory)][string]$Path)
  $bytes   = [System.IO.File]::ReadAllBytes($Path)
  $out     = New-Object 'System.Collections.Generic.List[byte]' $bytes.Length
  $changed = $false
  for ($i=0; $i -lt $bytes.Length; $i++) {
    if ($i -le $bytes.Length-3 -and $bytes[$i] -eq 0xEF -and $bytes[$i+1] -eq 0xBB -and $bytes[$i+2] -eq 0xBF) { $changed = $true; $i+=2; continue }
    $out.Add($bytes[$i])
  }
  if ($changed) { [System.IO.File]::WriteAllBytes($Path, $out.ToArray()); Write-Host "Stripped EF BB BF: $Path" }
}
function Remove-BomTree {
  param([Parameter(Mandatory)][string]$Root)
  Get-ChildItem -Path $Root -Recurse -File |
    Where-Object { $_.Extension -in '.py','.toml','.ini','.cfg','.txt' } |
    ForEach-Object { Remove-BomInFile -Path $_.FullName }
}

if ($Ci) {
  $env:KPI_PLAN_ADHERENCE = "0.90"
  $env:KPI_TOOL_SUCCESS   = "0.95"
  $env:KPI_TTFT_MS        = "300"
  $env:KPI_P95_DRY_MS     = "2000"
  $env:KPI_P95_RUN_MS     = "6000"
}

New-Item -ItemType Directory -Force -Path "metrics" | Out-Null
if (Test-Path metrics\canary_metrics.jsonl) { Remove-Item metrics\canary_metrics.jsonl -Force }

# სანიტაცია წყაროებზე (რეპოები/პაჩები/ტესტები)
Remove-BomTree "tests\canary\devops\repos"
Remove-BomTree "tests\canary\devops\patches"
Remove-BomTree "tests"

python -m pip install -U pip pytest
python -m pytest -q