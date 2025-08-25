param([switch]$RunDemos, [switch]$KeepServer, [switch]$Rebuild)
$ErrorActionPreference = "Stop"
try { chcp 65001 > $null; $OutputEncoding = [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false) } catch {}

$port = $env:PORT; if (-not $port) { $port = 8765 }
$venvPyPath = ".\.venv\Scripts\python.exe"

function New-Venv-Py311 {
  if (Get-Command py -ErrorAction SilentlyContinue) { & py -3.11 -m venv .venv; return }
  if (Get-Command python -ErrorAction SilentlyContinue) {
    $v = (& python -V) 2>&1
    if ($v -match "3\.11\.") { & python -m venv .venv; return }
  }
  throw "Python 3.11 not found. Install: winget install -e --id Python.Python.3.11"
}

# optional rebuild
if ($Rebuild -and (Test-Path .\.venv)) { try { Stop-Process -Name python -ErrorAction SilentlyContinue } catch {}; try { Remove-Item -Recurse -Force .\.venv } catch {} }

if (-not (Test-Path $venvPyPath)) { New-Venv-Py311 }
$venvPy = (Resolve-Path $venvPyPath).Path

& $venvPy -m pip install --upgrade pip > $null
& $venvPy -m pip install -r requirements.txt

$proc = Start-Process -FilePath $venvPy -ArgumentList @("-m","uvicorn","app:app","--host","0.0.0.0","--port",$port) -NoNewWindow -PassThru
"$( $proc.Id )" | Out-File -Encoding ascii "sena_local.pid"
Write-Host "SENA mock started. PID=$($proc.Id). Waiting for /health ..."

$ok = $false
for ($i=0; $i -lt 30; $i++) { try { Invoke-WebRequest "http://localhost:$port/health" -UseBasicParsing | Out-Null; $ok=$true; break } catch { Start-Sleep -Seconds 1 } }
if (-not $ok) { Write-Error "Server failed to start (no /health)"; exit 1 }
Write-Host "Health OK on http://localhost:$port/health"

if ($RunDemos) {
  if (-not (Get-Command jq -ErrorAction SilentlyContinue)) { Write-Warning "jq missing: winget install -e --id jqlang.jq" }
  powershell -ExecutionPolicy Bypass -File .\scripts\demo_rb_deep.ps1
  powershell -ExecutionPolicy Bypass -File .\scripts\demo_devops.ps1
}

if (-not $KeepServer) {
  Write-Host "Stopping server..."; try { Stop-Process -Id $proc.Id -Force } catch {}; Remove-Item "sena_local.pid" -ErrorAction SilentlyContinue; Write-Host "Done."
} else {
  Write-Host "Server left running (KeepServer). To stop: .\Stop-Local.ps1"
}