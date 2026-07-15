@echo off
REM ═══════════════════════════════════════════════════════════════════════════════
REM NitroWebExpress™ — Shutdown Frontend Modules (Windows)
REM Stops Tomcat and undeploys webapps.
REM Usage: scripts\shutdown-frontends.bat [--stop-tomcat]
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
echo ═══════════════════════════════════════════════════════════════
echo  NitroWebExpress™ — Shutdown Frontend Modules (Windows)
echo  Tomcat: %TOMCAT_HOME%
echo ═══════════════════════════════════════════════════════════════
echo.

REM ── Stop Tomcat ─────────────────────────────────────────────────────────────
echo [*] Stopping Tomcat...
net stop Tomcat11 2>nul && echo [OK] Tomcat11 service stopped || (
    if exist "%TOMCAT_HOME%\bin\shutdown.bat" (
        call "%TOMCAT_HOME%\bin\shutdown.bat" 2>nul
        echo [OK] Tomcat stopped via shutdown.bat
    ) else (
        echo [--] Tomcat not running or not found
    )
)

REM ── Undeploy webapps ────────────────────────────────────────────────────────
echo.
echo [*] Removing deployed webapps...
for %%C in (ae6e66,blackbelt,california-cia,california-duke,california-fbi,gray-registry,gray85-registry,gdgh,languages,library,california-nsa,futures,brarner.m.alete,strernary) do (
    if exist "%TOMCAT_HOME%\webapps\%%C" (
        rmdir /S /Q "%TOMCAT_HOME%\webapps\%%C" 2>nul
        echo   [OK] Removed /%%C
    )
)

echo.
echo [OK] Frontend shutdown complete
endlocal
