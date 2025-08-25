param([string]$Version="v0.2.0")
$ErrorActionPreference="Stop"
if (-not (Test-Path .git)) { Write-Error "Not a git repo"; exit 1 }
git add -A
git commit -m "SENA pilot $Version: docs, demos, assets" 2>$null
git tag -f $Version
"Tagged $Version"
$notes="RELEASE_NOTES_$($Version).md"
@"
# SENA $Version — Pilot Demo Ready
## What’s new
- Task I+J done; two hero workflows; KPIs gates

## KPIs Snapshot
- TTFT ≤ 0.30s; p95(dry) ≤ 2s; p95(run+tests) ≤ 6s
- Plan-Adherence ≥ 90%; Tool-Success ≥ 95%; RB hard claims Hallucination < 1%

## Known limits
- Mock engine for demo; offline cache after first run

## Assets
- docker-compose.yml, .env.example, demo scripts, screenshots, sample metrics, sample audit.zip
"@ | Set-Content -Encoding utf8 $notes
"Notes: $notes"

if (Get-Command gh -ErrorAction SilentlyContinue) {
  .\scripts\make_release_assets.ps1 -Version $Version | Out-Null
  gh release delete $Version -y 2>$null
  gh release create $Version -F $notes (Get-ChildItem -Recurse "release\$Version" -File | % FullName)
  "GitHub release created."
} else {
  "Install GitHub CLI to publish: winget install -e --id GitHub.cli"
}