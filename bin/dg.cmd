@echo off
:: dg — stable Windows bootstrap for Codex CLI + dual-graph
:: Keeps the entrypoint minimal and delegates launcher logic to PowerShell.

setlocal

set "DG=%USERPROFILE%\.dual-graph"
set "LOCAL_PS1=%DG%\dg.ps1"
set "LOCAL_CMD=%DG%\dg.cmd"
set "PENDING_CMD=%DG%\dg.cmd.new"
set "BOOTSTRAP_PS1=%TEMP%\dual_graph_dg_bootstrap.ps1"
set "REMOTE_PS1=https://raw.githubusercontent.com/kunal12203/Codex-CLI-Compact/main/bin/dg.ps1"
set "LOCAL_VER=%DG%\version.txt"
set "REMOTE_VER=https://raw.githubusercontent.com/kunal12203/Codex-CLI-Compact/main/bin/version.txt"
set "REMOTE_VER_FALLBACK=https://pub-18426978d5a14bf4a60ddedd7d5b6dab.r2.dev/version.txt"
set "INSTALL_METHOD=direct"
set "REPAIR_CMD=irm https://raw.githubusercontent.com/kunal12203/Codex-CLI-Compact/main/install.ps1 ^| iex"

if not exist "%DG%" mkdir "%DG%" >nul 2>&1

if exist "%PENDING_CMD%" (
  move /y "%PENDING_CMD%" "%LOCAL_CMD%" >nul 2>&1
)

if defined SCOOP (
  if exist "%SCOOP%\shims\dg.cmd" (
    set "INSTALL_METHOD=scoop"
    set "REPAIR_CMD=scoop update dual-graph"
  )
) else (
  if exist "%USERPROFILE%\scoop\shims\dg.cmd" (
    set "INSTALL_METHOD=scoop"
    set "REPAIR_CMD=scoop update dual-graph"
  )
)

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "try { Invoke-WebRequest '%REMOTE_PS1%' -OutFile '%LOCAL_PS1%' -UseBasicParsing -TimeoutSec 10 | Out-Null } catch {}; try { Invoke-WebRequest '%REMOTE_PS1%' -OutFile '%BOOTSTRAP_PS1%' -UseBasicParsing -TimeoutSec 10 | Out-Null } catch {}; try { Invoke-WebRequest '%REMOTE_VER%' -OutFile '%LOCAL_VER%' -UseBasicParsing -TimeoutSec 5 | Out-Null } catch { try { Invoke-WebRequest '%REMOTE_VER_FALLBACK%' -OutFile '%LOCAL_VER%' -UseBasicParsing -TimeoutSec 5 | Out-Null } catch {} }" >nul 2>&1

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

echo [dg] Error: bootstrap unavailable and local launcher missing.
if /i "%INSTALL_METHOD%"=="scoop" (
  echo [dg] Scoop is installed, but the local launcher payload is missing.
)
echo [dg] Run this once to repair the installation:
echo [dg]   %REPAIR_CMD%
exit /b 1
