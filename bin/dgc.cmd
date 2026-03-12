@echo off
:: dgc — stable Windows bootstrap for Claude Code + dual-graph
:: Keeps the entrypoint minimal and delegates launcher logic to PowerShell.

setlocal

set "DG=%USERPROFILE%\.dual-graph"
set "LOCAL_PS1=%DG%\dgc.ps1"
set "BOOTSTRAP_PS1=%TEMP%\dual_graph_dgc_bootstrap.ps1"
set "REMOTE_PS1=https://raw.githubusercontent.com/kunal12203/Codex-CLI-Compact/main/bin/dgc.ps1"

if not exist "%DG%" mkdir "%DG%" >nul 2>&1

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "try { Invoke-WebRequest '%REMOTE_PS1%' -OutFile '%BOOTSTRAP_PS1%' -UseBasicParsing -TimeoutSec 10; exit 0 } catch { exit 1 }" >nul 2>&1

if exist "%BOOTSTRAP_PS1%" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%BOOTSTRAP_PS1%" %*
  set "EXIT_CODE=%ERRORLEVEL%"
  del "%BOOTSTRAP_PS1%" >nul 2>&1
  exit /b %EXIT_CODE%
)

if exist "%LOCAL_PS1%" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%LOCAL_PS1%" %*
  exit /b %ERRORLEVEL%
)

echo [dgc] Error: bootstrap unavailable and local launcher missing.
echo [dgc] Run this once to repair the installation:
echo [dgc]   irm https://raw.githubusercontent.com/kunal12203/Codex-CLI-Compact/main/install.ps1 ^| iex
exit /b 1
