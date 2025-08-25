$pidFile = "sena_local.pid"
if (Test-Path $pidFile) {
  $ServerPid = [int](Get-Content $pidFile)
  try { Stop-Process -Id $ServerPid -Force; Write-Host "Stopped PID $ServerPid" } catch { Write-Warning $_ }
  Remove-Item $pidFile -ErrorAction SilentlyContinue
} else {
  Write-Warning "No pid file found ($pidFile). If server is running, stop it from Task Manager by python.exe"
}