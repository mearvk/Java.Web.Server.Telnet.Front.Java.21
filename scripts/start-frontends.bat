@echo off
REM ═══════════════════════════════════════════════════════════════════════════════
REM NitroWebExpress™ — Start Frontend Modules (Windows)
REM Deploys webapps to Tomcat and starts Tomcat.
REM Usage: scripts\start-frontends.bat [tomcat_home]
REM ═══════════════════════════════════════════════════════════════════════════════
setlocal enabledelayedexpansion

set "PROJECT_ROOT=%~dp0.."
pushd "%PROJECT_ROOT%"
set "PROJECT_ROOT=%CD%"
popd

REM ── Resolve TOMCAT_HOME ─────────────────────────────────────────────────────
set "NWE_CONFIG=%PROJECT_ROOT%\configuration\nwe-config.xml"
set "TOMCAT_HOME=C:\opt\apache-tomcat-11.0.2"
if not "%~1"=="" set "TOMCAT_HOME=%~1"
if "%~1"=="" (
    if exist "%NWE_CONFIG%" (
        for /f "delims=" %%A in ('powershell -NoProfile -Command "try { $d=([xml](Get-Content '%NWE_CONFIG%')).SelectSingleNode('//web-servers/tomcat/install-dir').InnerText; $d -replace '/','\'; } catch { '' }" 2^>nul') do (
            if not "%%A"=="" (
                set "TOMCAT_HOME=%%A"
                if "!TOMCAT_HOME:~0,4!"=="\opt" set "TOMCAT_HOME=C:!TOMCAT_HOME!"
            )
        )
    )
    if defined CATALINA_HOME set "TOMCAT_HOME=%CATALINA_HOME%"
)

echo.
echo ═══════════════════════════════════════════════════════════════
echo  NitroWebExpress™ — Start Frontend Modules (Windows)
echo  Tomcat: %TOMCAT_HOME%
echo ═══════════════════════════════════════════════════════════════
echo.

if not exist "%TOMCAT_HOME%\webapps" (
    echo [FAIL] Tomcat not found at %TOMCAT_HOME%
    exit /b 1
)

REM ── Deploy modules ──────────────────────────────────────────────────────────
echo [*] Deploying webapps...
set PASS=0
set FAIL=0

for %%M in (
    "modules\black\presidential\Brarner.M.Alete\install\deploy-local.sh"
    "modules\AE6E66\servlets\deploy-local.sh"
    "modules\red\Futures\servlets\deploy-local.sh"
    "modules\Green.Durham.Grass.and.Herb\servlets\deploy-local.sh"
    "modules\black-belt\servlets\deploy-local.sh"
    "modules\gray\servlets\deploy-local.sh"
    "modules\gray.a85\servlets\deploy-local.sh"
    "modules\languages\servlets\deploy-local.sh"
    "modules\fbi\servlets\deploy-local.sh"
    "modules\cia\servlets\deploy-local.sh"
    "modules\nsa\servlets\deploy-local.sh"
    "modules\duke\servlets\deploy-local.sh"
    "modules\library\servlets\deploy-local.sh"
    "source\strernary\servlets\deploy-local.sh"
) do (
    set "DSCRIPT=%PROJECT_ROOT%\%%~M"
    if exist "!DSCRIPT!" (
        where bash >nul 2>&1 && (
            bash "!DSCRIPT!" "%TOMCAT_HOME%" 2>nul && set /a PASS+=1 || set /a FAIL+=1
        ) || set /a FAIL+=1
    )
)
echo [OK] Deployed: %PASS% ^| Failed: %FAIL%

REM ── Start Tomcat ────────────────────────────────────────────────────────────
echo.
echo [*] Starting Tomcat...
sc query Tomcat11 2>nul | findstr "RUNNING" >nul && (
    echo [OK] Tomcat11 already running
) || (
    net start Tomcat11 2>nul && echo [OK] Tomcat11 service started || (
        if exist "%TOMCAT_HOME%\bin\startup.bat" (
            call "%TOMCAT_HOME%\bin\startup.bat" 2>nul
            echo [OK] Tomcat started via startup.bat
        ) else (
            echo [FAIL] Cannot start Tomcat
        )
    )
)

echo.
echo [OK] Frontend startup complete. http://localhost:8080/
endlocal
