@echo off
REM ═══════════════════════════════════════════════════════════════════════════════
REM NitroWebExpress™ — System Status (Windows)
REM Reports the status of all services (MySQL, backends, frontends).
REM Usage: scripts\status.bat
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
echo ║  NitroWebExpress™ — System Status Report (Windows)                        ║
echo ╚═══════════════════════════════════════════════════════════════════════════╝
echo.

REM ── MySQL ───────────────────────────────────────────────────────────────────
echo MySQL:
echo ───────────────────────────────────────────────────────────────────────────
mysqladmin ping --silent 2>nul >nul && (
    echo   [OK] MySQL is running
) || (
    sc query MySQL80 2>nul | findstr "RUNNING" >nul && (
        echo   [OK] MySQL80 service is running
    ) || (
        echo   [!!] MySQL is NOT running
    )
)
echo.

REM ── Tomcat ──────────────────────────────────────────────────────────────────
echo Tomcat / Web Services:
echo ───────────────────────────────────────────────────────────────────────────
curl -s -o nul -w "%%{http_code}" http://localhost:8080/ 2>nul > "%TEMP%\nwe-http.txt"
set /p HTTP_CODE=<"%TEMP%\nwe-http.txt"
del "%TEMP%\nwe-http.txt" 2>nul

if "%HTTP_CODE%"=="200" (echo   [OK] Tomcat is running ^(HTTP %HTTP_CODE%^)) else (
if "%HTTP_CODE%"=="302" (echo   [OK] Tomcat is running ^(HTTP %HTTP_CODE%^)) else (
    sc query Tomcat11 2>nul | findstr "RUNNING" >nul && (
        echo   [OK] Tomcat11 service running ^(HTTP %HTTP_CODE%^)
    ) || (
        echo   [!!] Tomcat is NOT responding ^(HTTP %HTTP_CODE%^)
    )
))
echo   Tomcat home: %TOMCAT_HOME%
echo.

REM ── Backend Modules ─────────────────────────────────────────────────────────
echo Backend Modules (TCP Servers):
echo ───────────────────────────────────────────────────────────────────────────

set BACKENDS_UP=0
set BACKENDS_DOWN=0

REM Check NWE Main process
if exist "%PROJECT_ROOT%\data\nwe-main.pid" (
    set /p NWE_PID=<"%PROJECT_ROOT%\data\nwe-main.pid"
    tasklist /FI "PID eq !NWE_PID!" 2>nul | findstr "!NWE_PID!" >nul && (
        echo   [OK] NWE Main ^(PID !NWE_PID!^)
        set /a BACKENDS_UP+=1
    ) || (
        echo   [!!] NWE Main ^(PID !NWE_PID! — not running^)
        set /a BACKENDS_DOWN+=1
    )
) else (
    echo   [--] NWE Main ^(not started^)
    set /a BACKENDS_DOWN+=1
)

REM Check key ports
for %%P in (49152,20000,2000,5512,6682,7743,7744,49199) do (
    powershell -NoProfile -Command "try { $t = New-Object Net.Sockets.TcpClient; $t.Connect('localhost',%%P); $t.Close(); exit 0 } catch { exit 1 }" 2>nul && (
        echo   [OK] Port %%P — listening
        set /a BACKENDS_UP+=1
    ) || (
        echo   [--] Port %%P — not listening
        set /a BACKENDS_DOWN+=1
    )
)
echo   Backends up: %BACKENDS_UP%
echo.

REM ── Frontend Modules ────────────────────────────────────────────────────────
echo Frontend Modules (Tomcat Webapps):
echo ───────────────────────────────────────────────────────────────────────────

set FRONTENDS_UP=0
set FRONTENDS_DOWN=0

for %%C in (ae6e66,blackbelt,california-cia,california-duke,california-fbi,gray-registry,gray85-registry,gdgh,languages,library,california-nsa,futures,brarner.m.alete) do (
    curl -s -o nul -w "%%{http_code}" "http://localhost:8080/%%C/" 2>nul > "%TEMP%\nwe-ctx.txt"
    set /p CTX_CODE=<"%TEMP%\nwe-ctx.txt"
    del "%TEMP%\nwe-ctx.txt" 2>nul
    if "!CTX_CODE!"=="200" (
        echo   [OK] /%%C
        set /a FRONTENDS_UP+=1
    ) else if "!CTX_CODE!"=="302" (
        echo   [OK] /%%C
        set /a FRONTENDS_UP+=1
    ) else (
        echo   [--] /%%C ^(HTTP !CTX_CODE!^)
        set /a FRONTENDS_DOWN+=1
    )
)
echo   Frontends up: %FRONTENDS_UP%
echo.

REM ── Summary ─────────────────────────────────────────────────────────────────
echo ╔═══════════════════════════════════════════════════════════════════════════╗
echo ║  Start:     scripts\start-all.bat                                         ║
echo ║  Shutdown:  scripts\shutdown-all.bat                                      ║
echo ╚═══════════════════════════════════════════════════════════════════════════╝
echo.
endlocal
