@echo off
REM ═══════════════════════════════════════════════════════════════════════════════
REM NitroWebExpress™ — Deploy All Web Modules (Windows)
REM Reads configuration from nwe-config.xml and web-deploy-config.xml.
REM Usage: scripts\web\deploy-all.bat
REM ═══════════════════════════════════════════════════════════════════════════════
setlocal enabledelayedexpansion

set "SCRIPT_DIR=%~dp0"
set "PROJECT_ROOT=%SCRIPT_DIR%..\.."
pushd "%PROJECT_ROOT%"
set "PROJECT_ROOT=%CD%"
popd
set "CONFIG=%SCRIPT_DIR%web-deploy-config.xml"
set "NWE_CONFIG=%PROJECT_ROOT%\configuration\nwe-config.xml"

echo.
echo ═══════════════════════════════════════════════════════════════
echo  NitroWebExpress™ — Deploy All Web Modules (Windows)
echo  Config: %CONFIG%
echo  Root:   %PROJECT_ROOT%
echo ═══════════════════════════════════════════════════════════════
echo.

if not exist "%CONFIG%" (
    echo [FAIL] Config not found: %CONFIG%
    exit /b 1
)

REM ── Resolve TOMCAT_HOME (priority: nwe-config.xml > web-deploy-config.xml > CATALINA_HOME > default) ──
set "TOMCAT_HOME="

REM Try nwe-config.xml
if exist "%NWE_CONFIG%" (
    for /f "delims=" %%A in ('powershell -NoProfile -Command "try { ([xml](Get-Content '%NWE_CONFIG%')).SelectSingleNode('//web-servers/tomcat/install-dir').InnerText } catch { '' }" 2^>nul') do (
        if not "%%A"=="" (
            set "TOMCAT_HOME=%%A"
            set "TOMCAT_HOME=!TOMCAT_HOME:/=\!"
            if "!TOMCAT_HOME:~0,4!"=="\opt" set "TOMCAT_HOME=C:!TOMCAT_HOME!"
        )
    )
)

REM Try web-deploy-config.xml
if not defined TOMCAT_HOME (
    for /f "delims=" %%A in ('powershell -NoProfile -Command "try { ([xml](Get-Content '%CONFIG%')).SelectSingleNode('//tomcat-home').InnerText } catch { '' }" 2^>nul') do (
        if not "%%A"=="" (
            set "TOMCAT_HOME=%%A"
            set "TOMCAT_HOME=!TOMCAT_HOME:/=\!"
            if "!TOMCAT_HOME:~0,4!"=="\opt" set "TOMCAT_HOME=C:!TOMCAT_HOME!"
        )
    )
)

REM Try CATALINA_HOME
if not defined TOMCAT_HOME if defined CATALINA_HOME set "TOMCAT_HOME=%CATALINA_HOME%"

REM Final default
if not defined TOMCAT_HOME set "TOMCAT_HOME=C:\opt\apache-tomcat-11.0.2"

echo [*] Tomcat: %TOMCAT_HOME%

if not exist "%TOMCAT_HOME%\webapps" (
    echo [FAIL] Tomcat not found at %TOMCAT_HOME%
    echo        Set CATALINA_HOME or run post-clone.bat first.
    exit /b 1
)

REM ── Setup databases ─────────────────────────────────────────────────────────
echo.
echo [*] Setting up module databases...
where bash >nul 2>&1 && (
    bash "%PROJECT_ROOT%/scripts/web/setup-all-databases.sh" 2>nul
    echo [OK] Databases configured
) || (
    echo [WARN] Git Bash not available — databases may need manual setup
)

REM ── Deploy modules ──────────────────────────────────────────────────────────
echo.
set PASS=0
set FAIL=0

set "MODULES=modules\black\presidential\Brarner.M.Alete\install\deploy-local.sh"
set "MODULES=%MODULES%;modules\AE6E66\servlets\deploy-local.sh"
set "MODULES=%MODULES%;modules\red\Futures\servlets\deploy-local.sh"
set "MODULES=%MODULES%;modules\Green.Durham.Grass.and.Herb\servlets\deploy-local.sh"
set "MODULES=%MODULES%;modules\black-belt\servlets\deploy-local.sh"
set "MODULES=%MODULES%;modules\gray\servlets\deploy-local.sh"
set "MODULES=%MODULES%;modules\gray.a85\servlets\deploy-local.sh"
set "MODULES=%MODULES%;modules\languages\servlets\deploy-local.sh"
set "MODULES=%MODULES%;modules\fbi\servlets\deploy-local.sh"
set "MODULES=%MODULES%;modules\cia\servlets\deploy-local.sh"
set "MODULES=%MODULES%;modules\nsa\servlets\deploy-local.sh"
set "MODULES=%MODULES%;modules\duke\servlets\deploy-local.sh"
set "MODULES=%MODULES%;modules\library\servlets\deploy-local.sh"
set "MODULES=%MODULES%;source\strernary\servlets\deploy-local.sh"

for %%M in (%MODULES%) do (
    set "SCRIPT_PATH=%PROJECT_ROOT%\%%M"
    if exist "!SCRIPT_PATH!" (
        echo [*] Deploying: %%M
        where bash >nul 2>&1 && (
            bash "!SCRIPT_PATH!" "%TOMCAT_HOME%" 2>nul && set /a PASS+=1 || set /a FAIL+=1
        ) || (
            echo     [!] bash not available — skipping
            set /a FAIL+=1
        )
    ) else (
        echo [--] Not found: %%M
        set /a FAIL+=1
    )
)

REM ── Register Tomcat service ─────────────────────────────────────────────────
echo.
if exist "%TOMCAT_HOME%\bin\service.bat" (
    echo [*] Registering Tomcat as Windows service...
    call "%TOMCAT_HOME%\bin\service.bat" install Tomcat11 2>nul
    sc config Tomcat11 start= auto 2>nul
    echo [OK] Tomcat11 set to auto-start
)

REM ── Sync tomcat-home back ───────────────────────────────────────────────────
set "TOMCAT_HOME_UNIX=%TOMCAT_HOME:\=/%"
powershell -NoProfile -Command "try { $xml = [xml](Get-Content '%CONFIG%'); $xml.SelectSingleNode('//tomcat-home').InnerText = '%TOMCAT_HOME_UNIX%'; $xml.Save('%CONFIG%') } catch {}" 2>nul

echo.
echo ═══════════════════════════════════════════════════════════════
echo  Results: %PASS% deployed ^| %FAIL% failed
echo  Start:   net start Tomcat11
echo  Tomcat:  %TOMCAT_HOME%
echo ═══════════════════════════════════════════════════════════════
endlocal
