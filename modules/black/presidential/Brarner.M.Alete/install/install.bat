@echo off
REM Brarner.M.Alete™ — Install Script (Windows)
REM Deploys the BMA servlet website to a local Tomcat container.
setlocal enabledelayedexpansion

set "SCRIPT_DIR=%~dp0"
set "BMA_ROOT=%SCRIPT_DIR%.."
set "WEBAPP_SRC=%BMA_ROOT%\servlets\servlet\src\main\webapp"
set "DEPLOY_DIR=C:\opt\bma"

echo ═══════════════════════════════════════════════════════════════
echo  Brarner.M.Alete™ — Website Installer (Windows)
echo  MEARVK LLC — NC Socialist-College Block
echo ═══════════════════════════════════════════════════════════════

REM Check Java
where java >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] Java not found. Install JDK 21+ first.
    exit /b 1
)
for /f "tokens=3" %%v in ('java -version 2^>^&1 ^| findstr /i "version"') do set "JAVA_VER=%%~v"
echo [*] Java detected: %JAVA_VER%

REM Create deploy directory
echo [*] Creating deploy directory: %DEPLOY_DIR%
if not exist "%DEPLOY_DIR%" mkdir "%DEPLOY_DIR%"
if not exist "%DEPLOY_DIR%\webapp" mkdir "%DEPLOY_DIR%\webapp"
if not exist "%DEPLOY_DIR%\lib" mkdir "%DEPLOY_DIR%\lib"
if not exist "%DEPLOY_DIR%\logs" mkdir "%DEPLOY_DIR%\logs"

REM Copy webapp
echo [*] Copying webapp files...
xcopy /E /Y /Q "%WEBAPP_SRC%\*" "%DEPLOY_DIR%\webapp\" >nul

REM Copy JARs
if exist "%BMA_ROOT%\lib\*.jar" (
    echo [*] Copying library JARs...
    copy /Y "%BMA_ROOT%\lib\*.jar" "%DEPLOY_DIR%\lib\" >nul
)

REM Deploy to Tomcat if CATALINA_HOME set
if defined CATALINA_HOME (
    echo [*] Tomcat detected: %CATALINA_HOME%
    if not exist "%CATALINA_HOME%\webapps\bma" mkdir "%CATALINA_HOME%\webapps\bma"
    xcopy /E /Y /Q "%WEBAPP_SRC%\*" "%CATALINA_HOME%\webapps\bma\" >nul
    if exist "%BMA_ROOT%\lib\*.jar" (
        if not exist "%CATALINA_HOME%\webapps\bma\WEB-INF\lib" mkdir "%CATALINA_HOME%\webapps\bma\WEB-INF\lib"
        copy /Y "%BMA_ROOT%\lib\*.jar" "%CATALINA_HOME%\webapps\bma\WEB-INF\lib\" >nul
    )
    echo [*] Deployed to Tomcat: %CATALINA_HOME%\webapps\bma
) else (
    echo [*] CATALINA_HOME not set — skipping Tomcat deploy.
)

echo.
echo [OK] Installation complete.
echo     Deploy dir: %DEPLOY_DIR%
echo     Run download-jars.bat to fetch required dependencies.
echo ═══════════════════════════════════════════════════════════════
endlocal
