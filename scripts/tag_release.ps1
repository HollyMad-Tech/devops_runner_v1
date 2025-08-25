param([Parameter(Mandatory)][string]$Version)
$ErrorActionPreference = "Stop"

if (-not (Test-Path .git)) { Write-Error "Not a git repo"; exit 1 }

git add -A
# უსაფრთხო ფორმატირება (აიცილებს `$Version:` გაუგებრობას)
git commit -m ("SENA pilot {0}: docs, demos, assets" -f $Version) 2>$null

# ტეგი და push-ები
git tag -f $Version
git push -u origin HEAD
git push -f origin $Version

# სურვილისამებრ GitHub Release
if (Get-Command gh -ErrorAction SilentlyContinue) {
  & .\scripts\make_release_assets.ps1 -Version $Version | Out-Null

  $notes = "RELEASE_NOTES_$Version.md"
  if (-not (Test-Path $notes)) { "# $Version" | Set-Content -Encoding utf8 $notes }

  $assets = @(Get-ChildItem -Recurse -File (Join-Path "release" $Version) | ForEach-Object FullName)

  gh release delete $Version -y 2>$null
  gh release create $Version -F $notes @assets
  "GitHub release created."
} else {
  "Install GitHub CLI to publish: winget install -e --id GitHub.cli"
}
