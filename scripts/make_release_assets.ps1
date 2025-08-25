param([string]$Version="v0.2.0")
$root = Join-Path "release" $Version
New-Item -ItemType Directory -Force -Path $root | Out-Null
$files = @(
  ".env.example","docker-compose.yml","Dockerfile","requirements.txt","app.py",
  "scripts/demo_rb_deep.ps1","scripts/demo_devops.ps1","scripts/demo_rb_deep.sh","scripts/demo_devops.sh",
  "docs/README.md","docs/RUNBOOK.md","docs/API.md","docs/SDK.md","docs/DEMO_RB_DEEP.md","docs/DEMO_DEVOPS.md","docs/SECURITY.md","docs/LICENSING.md","docs/FAQ.md"
)
$files | % { if (Test-Path $_) { Copy-Item $_ -Destination (Join-Path $root $_) -Force -Recurse } }
# latest exports/audits
Get-ChildItem workspace\exports -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 6 | Copy-Item -Destination (Join-Path $root "workspace/exports") -Force
$aud = Get-ChildItem workspace\audit -Directory -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 2
$aud | % { Copy-Item $_.FullName -Destination (Join-Path $root "workspace/audit") -Force -Recurse }
# screenshots/sample metrics
if (Test-Path assets) { Copy-Item assets\* -Destination (Join-Path $root "assets") -Force -Recurse }
# checksums
Push-Location $root
Get-ChildItem -Recurse -File | Get-FileHash -Algorithm SHA256 | ForEach-Object { "{0}  {1}" -f $_.Hash.ToLower(), $_.Path.Substring($PWD.Path.Length+1) } | Set-Content -Encoding ascii "SHA256SUMS.txt"
Pop-Location
"Release assets ready at $root"