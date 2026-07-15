@echo off
REM ═══════════════════════════════════════════════════════════════════════════════
REM NitroWebExpress™ — Shutdown Backend Modules (Windows)
REM Stops the NWE Main process and all backend TCP servers.
REM Usage: scripts\shutdown-backends.bat
REM ═══════════════════════════════════════════════════════════════════════════════
setlocal enabledelayedexpansion

set "PROJECT_ROOT=%~dp0.."
pushd "%PROJECT_ROOT%"
set "PROJECT_ROOT=%CD%"
popd

set "PID_FILE=%PROJECT_ROOT%\data\nwe-main.pid"

echo [*] Shutting down NWE backend modules...

REM ── Kill from PID file ──────────────────────────────────────────────────────
if exist "%PID_FILE%" (
    set /p NWE_PID=<"%PID_FILE%"
    tasklist /FI "PID eq !NWE_PID!" 2>nul | findstr "!NWE_PID!" >nul && (
        taskkill /PID !NWE_PID! /T /F >nul 2>&1
        echo [OK] Main process ^(PID !NWE_PID!^) terminated
    ) || (
        echo [--] Process !NWE_PID! was not running
    )
    del "%PID_FILE%" 2>nul
) else (
    echo [--] No PID file found
)

REM ── Kill module backend PIDs ────────────────────────────────────────────────
for %%M in (AE6E66,cia,duke,fbi,gray,gray.a85,Green.Durham.Grass.and.Herb,library,nsa) do (
    set "MOD_PID=%PROJECT_ROOT%\modules\%%M\data\pids\backend.pid"
    if exist "!MOD_PID!" (
        set /p MPID=<"!MOD_PID!"
        taskkill /PID !MPID! /T /F >nul 2>&1
        del "!MOD_PID!" 2>nul
        echo   [OK] %%M stopped
    )
)

REM Futures special path
set "FUTURES_PID=%PROJECT_ROOT%\modules\red\Futures\data\pids\backend.pid"
if exist "%FUTURES_PID%" (
    set /p FPID=<"%FUTURES_PID%"
    taskkill /PID !FPID! /T /F >nul 2>&1
    del "%FUTURES_PID%" 2>nul
    echo   [OK] Futures stopped
)

REM ── Cleanup any orphaned NWE java processes ─────────────────────────────────
taskkill /F /FI "WINDOWTITLE eq NitroWebExpress*" >nul 2>&1

echo.
echo [OK] All backend modules stopped
endlocal
