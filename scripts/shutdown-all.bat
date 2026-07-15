@echo off
REM ═══════════════════════════════════════════════════════════════════════════════
REM NitroWebExpress™ — Shutdown All Services (Windows)
REM Sequence: Frontends → Backends → MySQL
REM Usage: scripts\shutdown-all.bat
REM ═══════════════════════════════════════════════════════════════════════════════
setlocal enabledelayedexpansion

set "PROJECT_ROOT=%~dp0.."
pushd "%PROJECT_ROOT%"
set "PROJECT_ROOT=%CD%"
popd

set "NWE_CONFIG=%PROJECT_ROOT%\configuration\nwe-config.xml"
set "TOMCAT_HOME=C:\opt\apache-tomcat-11.0.2"
if exist "%NWE_CONFIG%" (
    for /f "delims=" %%A in ('powershell -NoProfile -Command "try { $d=([xml](Get-Content '%NWE_CONFIG%')).SelectSingleNode('//web-servers/tomcat/install-dir').InnerText; $d -replace '/','\'; } catch { '' }" 2^>nul') do (
        if not "%%A"=="" (
            set "TOMCAT_HOME=%%A"
            if "!TOMCAT_HOME:~0,4!"=="\opt" set "TOMCAT_HOME=C:!TOMCAT_HOME!"
        )
    )
)
if defined CATALINA_HOME set "TOMCAT_HOME=%CATALINA_HOME%"

echo.
echo ╔═══════════════════════════════════════════════════════════════════════════╗
echo ║                                                                           ║
echo ║   NitroWebExpress™ — Complete System Shutdown (Windows)                   ║
echo ║   Sequence: Frontends → Backends → MySQL                                  ║
echo ║                                                                           ║
echo ╚═══════════════════════════════════════════════════════════════════════════╝
echo.

REM ── Phase 1: Frontends / Tomcat ─────────────────────────────────────────────
echo ───────────────────────────────────────────────────────────────────────────────
echo Phase 1/3: Shutting Down Frontend Modules / Tomcat...
echo ───────────────────────────────────────────────────────────────────────────────
echo.

net stop Tomcat11 2>nul && echo   [OK] Tomcat11 service stopped || (
    if exist "%TOMCAT_HOME%\bin\shutdown.bat" (
        call "%TOMCAT_HOME%\bin\shutdown.bat" 2>nul
        echo   [OK] Tomcat stopped via shutdown.bat
    ) else (
        echo   [--] Tomcat not running or not found
    )
)
timeout /t 2 /nobreak >nul

REM ── Phase 2: Backends ───────────────────────────────────────────────────────
echo.
echo ───────────────────────────────────────────────────────────────────────────────
echo Phase 2/3: Shutting Down Backend Modules...
echo ───────────────────────────────────────────────────────────────────────────────
echo.

if exist "%PROJECT_ROOT%\scripts\shutdown-backends.bat" (
    call "%PROJECT_ROOT%\scripts\shutdown-backends.bat"
) else (
    REM Kill from PID file
    set "PID_FILE=%PROJECT_ROOT%\data\nwe-main.pid"
    if exist "!PID_FILE!" (
        set /p NWE_PID=<"!PID_FILE!"
        taskkill /PID !NWE_PID! /T /F 2>nul && (
            echo   [OK] Main process (PID !NWE_PID!) terminated
            del "!PID_FILE!" 2>nul
        ) || (
            echo   [--] Process !NWE_PID! not running
            del "!PID_FILE!" 2>nul
        )
    ) else (
        echo   [--] No PID file found — backends may not be running
    )
    REM Kill any remaining NWE java processes
    taskkill /F /FI "WINDOWTITLE eq NitroWebExpress*" 2>nul
)
echo   [OK] Backend shutdown complete
timeout /t 2 /nobreak >nul

REM ── Phase 3: MySQL ──────────────────────────────────────────────────────────
echo.
echo ───────────────────────────────────────────────────────────────────────────────
echo Phase 3/3: Shutting Down MySQL...
echo ───────────────────────────────────────────────────────────────────────────────
echo.

net stop MySQL80 2>nul || net stop MySQL 2>nul || (
    echo   [--] MySQL service not found or already stopped
)
echo   [OK] MySQL shutdown complete

REM ── Remove firewall rules ───────────────────────────────────────────────────
echo.
echo [*] Removing firewall rules...
for %%P in (2000,5000,5512,6682,7743,7744,8080,9999,10085,20000,49111,49144,49152,49155,49166,49177,49188,49199,49200,49201,49202,49203,49204,49210,49211,49212,49213,49214) do (
    netsh advfirewall firewall delete rule name="NWE-%%P" >nul 2>&1
)
echo [OK] Firewall rules removed

echo.
echo ╔═══════════════════════════════════════════════════════════════════════════╗
echo ║                                                                           ║
echo ║   NitroWebExpress™ System Shutdown Complete!                              ║
echo ║   Restart: scripts\start-all.bat                                          ║
echo ║                                                                           ║
echo ╚═══════════════════════════════════════════════════════════════════════════╝
echo.
endlocal
