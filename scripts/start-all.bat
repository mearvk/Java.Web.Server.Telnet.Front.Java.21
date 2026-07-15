@echo off
REM ═══════════════════════════════════════════════════════════════════════════════
REM NitroWebExpress™ — Start All Services (Windows)
REM Sequence: MySQL → Compile → Backends → Frontends
REM Usage: scripts\start-all.bat
REM ═══════════════════════════════════════════════════════════════════════════════
setlocal enabledelayedexpansion

set "PROJECT_ROOT=%~dp0.."
pushd "%PROJECT_ROOT%"
set "PROJECT_ROOT=%CD%"
popd

REM ── Resolve TOMCAT_HOME ─────────────────────────────────────────────────────
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
echo ║   NitroWebExpress™ — Complete System Startup (Windows)                    ║
echo ║   Sequence: MySQL → Compile → Backends → Frontends                        ║
echo ║                                                                           ║
echo ╚═══════════════════════════════════════════════════════════════════════════╝
echo.

REM ── Phase 0: Stop existing ──────────────────────────────────────────────────
echo ───────────────────────────────────────────────────────────────────────────────
echo Pre-flight: Checking for running services...
echo ───────────────────────────────────────────────────────────────────────────────
echo.

curl -s -o nul http://localhost:8080/ 2>nul && (
    echo   [*] Tomcat is running — stopping before redeploy
    call "%PROJECT_ROOT%\scripts\shutdown-all.bat" 2>nul
    timeout /t 3 /nobreak >nul
)

REM ── Phase 1: MySQL ──────────────────────────────────────────────────────────
echo.
echo ───────────────────────────────────────────────────────────────────────────────
echo Phase 1/4: Starting MySQL...
echo ───────────────────────────────────────────────────────────────────────────────
echo.

net start MySQL80 2>nul || net start MySQL 2>nul || (
    echo   [!] MySQL service not found — trying mysqld...
    start /b mysqld 2>nul
)
timeout /t 2 /nobreak >nul
mysqladmin ping --silent 2>nul >nul && (
    echo   [OK] MySQL is running
) || (
    echo   [!] MySQL may not be running — continuing anyway
)

REM ── Phase 2: Compile ────────────────────────────────────────────────────────
echo.
echo ───────────────────────────────────────────────────────────────────────────────
echo Phase 2/4: Compiling All Modules...
echo ───────────────────────────────────────────────────────────────────────────────
echo.

if exist "%PROJECT_ROOT%\scripts\compile-all-modules.bat" (
    call "%PROJECT_ROOT%\scripts\compile-all-modules.bat"
    echo   [OK] Compilation complete
) else (
    where bash >nul 2>&1 && (
        bash "%PROJECT_ROOT%/scripts/compile-all-modules.sh"
        echo   [OK] Compilation complete (via bash)
    ) || (
        echo   [!] No compile script available — skipping
    )
)

REM ── Phase 3: Backends ───────────────────────────────────────────────────────
echo.
echo ───────────────────────────────────────────────────────────────────────────────
echo Phase 3/4: Starting Backend Modules...
echo ───────────────────────────────────────────────────────────────────────────────
echo.

if exist "%PROJECT_ROOT%\scripts\start-backends.bat" (
    call "%PROJECT_ROOT%\scripts\start-backends.bat"
) else (
    where bash >nul 2>&1 && (
        bash "%PROJECT_ROOT%/scripts/start-backends.sh"
    ) || (
        echo   [!] Cannot start backends — no script available
    )
)
echo   [OK] Backend startup initiated
timeout /t 3 /nobreak >nul

REM ── Phase 4: Frontends ──────────────────────────────────────────────────────
echo.
echo ───────────────────────────────────────────────────────────────────────────────
echo Phase 4/4: Starting Frontend Modules...
echo ───────────────────────────────────────────────────────────────────────────────
echo.

if exist "%PROJECT_ROOT%\scripts\start-frontends.bat" (
    call "%PROJECT_ROOT%\scripts\start-frontends.bat"
) else (
    REM Start Tomcat directly
    if exist "%TOMCAT_HOME%\bin\catalina.bat" (
        call "%TOMCAT_HOME%\bin\startup.bat" 2>nul
        echo   [OK] Tomcat started
    ) else (
        net start Tomcat11 2>nul && echo   [OK] Tomcat11 service started
    )
)

REM ── Open firewall ports ─────────────────────────────────────────────────────
echo.
echo [*] Opening firewall ports...
for %%P in (2000,5000,5512,6682,7743,7744,8080,9999,10085,20000,49111,49144,49152,49155,49166,49177,49188,49199,49200,49201,49202,49203,49204,49210,49211,49212,49213,49214) do (
    netsh advfirewall firewall add rule name="NWE-%%P" dir=in action=allow protocol=TCP localport=%%P >nul 2>&1
)
echo [OK] Firewall ports opened

REM ── Summary ─────────────────────────────────────────────────────────────────
echo.
echo ╔═══════════════════════════════════════════════════════════════════════════╗
echo ║                                                                           ║
echo ║   NitroWebExpress™ System Startup Complete!                               ║
echo ║                                                                           ║
echo ║   Verify:     scripts\status.bat                                          ║
echo ║   Shutdown:   scripts\shutdown-all.bat                                    ║
echo ║   Tomcat:     %TOMCAT_HOME%
echo ║                                                                           ║
echo ╚═══════════════════════════════════════════════════════════════════════════╝
echo.
endlocal
