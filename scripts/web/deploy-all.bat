@echo off
REM NitroWebExpress™ — Deploy All Web Modules (Windows)
REM Reads web-deploy-config.xml and deploys enabled modules.
REM Usage: scripts\web\deploy-all.bat
setlocal enabledelayedexpansion

set SCRIPT_DIR=%~dp0
set PROJECT_ROOT=%SCRIPT_DIR%..\..
set CONFIG=%SCRIPT_DIR%web-deploy-config.xml

echo ═══════════════════════════════════════════════════════════════
echo  NitroWebExpress™ — Deploy All Web Modules (Windows)
echo  Config: %CONFIG%
echo ═══════════════════════════════════════════════════════════════

if not exist "%CONFIG%" (
    echo [FAIL] Config not found: %CONFIG%
    exit /b 1
)

REM Find Tomcat
set TOMCAT_HOME=%CATALINA_HOME%
if "%TOMCAT_HOME%"=="" set TOMCAT_HOME=C:\opt\tomcat
if not exist "%TOMCAT_HOME%\webapps" (
    echo [!] Tomcat not found at %TOMCAT_HOME%
    echo     Set CATALINA_HOME or install Tomcat to C:\opt\tomcat
    exit /b 1
)

set PASS=0
set FAIL=0

REM Deploy each module that has a .bat or use embedded Tomcat
for %%M in (
    "modules\black\presidential\Brarner.M.Alete\install\deploy-local.sh"
    "modules\AE6E66\servlets\deploy-local.sh"
    "modules\black\red\Futures\servlets\deploy-local.sh"
    "modules\black\presidential\Green.Durham.Grass.and.Herb\servlets\deploy-local.sh"
    "modules\black\belt\servlets\deploy-local.sh"
    "modules\gray\servlets\deploy-local.sh"
    "modules\gray.a85\servlets\deploy-local.sh"
    "modules\languages\servlets\deploy-local.sh"
    "source\strernary\servlets\deploy-local.sh"
    "california\fbi\servlets\deploy-local.sh"
    "california\cia\servlets\deploy-local.sh"
    "california\nsa\servlets\deploy-local.sh"
    "north\carolina\duke\servlets\deploy-local.sh"
    "north\carolina\library\servlets\deploy-local.sh"
) do (
    set SCRIPT=%PROJECT_ROOT%\%%~M
    if exist "!SCRIPT!" (
        echo [*] Deploying: %%~M
        REM Use Git Bash or WSL to run .sh scripts on Windows
        where bash >nul 2>&1 && (
            bash "!SCRIPT!" "%TOMCAT_HOME%" && set /a PASS+=1 || set /a FAIL+=1
        ) || (
            echo [!] bash not available - install Git Bash or WSL
            set /a FAIL+=1
        )
    ) else (
        echo [!] Not found: %%~M
        set /a FAIL+=1
    )
)

REM Register Tomcat as Windows service for reboot
if exist "%TOMCAT_HOME%\bin\service.bat" (
    echo [*] Registering Tomcat as Windows service...
    call "%TOMCAT_HOME%\bin\service.bat" install 2>nul
    sc config Tomcat11 start= auto 2>nul
    echo [OK] Tomcat set to auto-start on reboot
)

echo.
echo ═══════════════════════════════════════════════════════════════
echo  Results: %PASS% deployed ^| %FAIL% failed
echo  Start: net start Tomcat11
echo ═══════════════════════════════════════════════════════════════
endlocal
