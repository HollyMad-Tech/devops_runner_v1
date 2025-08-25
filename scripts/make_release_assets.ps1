param([Parameter(Mandatory)][string]$Version)
$ErrorActionPreference = "Stop"

$root = Join-Path "release" $Version
New-Item -ItemType Directory -Force -Path $root | Out-Null

# ძირითადი ფაილები
$files = @(
  ".env.example","docker-compose.yml","Dockerfile","requirements.txt","app.py",
  "Start-Local.ps1","Stop-Local.ps1",
  "scripts/demo_rb_deep.ps1","scripts/demo_devops.ps1","scripts/demo_rb_deep.sh","scripts/demo_devops.sh",
  "docs/README.md","docs/RUNBOOK.md","docs/API.md","docs/SDK.md",
  "docs/DEMO_RB_DEEP.md","docs/DEMO_DEVOPS.md","docs/SECURITY.md","docs/LICENSING.md","docs/FAQ.md"
)

foreach ($src in $files) {
  if (Test-Path $src) {
    $dest    = Join-Path $root $src
    $destDir = Split-Path -Parent $dest
    if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Force -Path $destDir | Out-Null }
    Copy-Item $src -Destination $dest -Force
  }
}

# ბოლო exports და audits
$exportsDir = Join-Path $root "workspace/exports"
$auditsDir  = Join-Path $root "workspace/audit"
New-Item -ItemType Directory -Force -Path $exportsDir, $auditsDir | Out-Null

if (Test-Path "workspace\exports") {
  Get-ChildItem "workspace\exports" -File -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending | Select-Object -First 6 |
    Copy-Item -Destination $exportsDir -Force
}
if (Test-Path "workspace\audit") {
  Get-ChildItem "workspace\audit" -Directory -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending | Select-Object -First 2 |
    ForEach-Object { Copy-Item $_.FullName -Destination $auditsDir -Force -Recurse }
}

# screenshots/sample metrics
if (Test-Path assets) {
  $assetsDest = Join-Path $root "assets"
  New-Item -ItemType Directory -Force -Path $assetsDest | Out-Null
  Copy-Item assets\* -Destination $assetsDest -Force -Recurse
}

# checksums — გამორიცხე თავად checksums ფაილი
Push-Location $root
$sumFile = "SHA256SUMS.txt"
if (Test-Path $sumFile) { Remove-Item $sumFile -Force }
$sumPath = Join-Path $PWD.Path $sumFile

$filesToHash = Get-ChildItem -Recurse -File | Where-Object { $_.FullName -ne $sumPath }
$lines = foreach ($f in $filesToHash) {
  $h = Get-FileHash -Algorithm SHA256 -Path $f.FullName
  "{0}  {1}" -f $h.Hash.ToLower(), $f.FullName.Substring($PWD.Path.Length+1)
}
Set-Content -Encoding ascii -Path $sumFile -Value $lines
Pop-Location

"Release assets ready at $root"
