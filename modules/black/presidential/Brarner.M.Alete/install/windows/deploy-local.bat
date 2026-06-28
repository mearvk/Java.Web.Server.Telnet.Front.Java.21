@echo off
REM Brarner.M.Alete™ — Deploy Local (Windows)
REM Deploys webapp to local Tomcat
REM Usage: install\windows\deploy-local.bat [tomcat_home]

setlocal enabledelayedexpansion

set SCRIPT_DIR=%~dp0
set BMA_ROOT=%SCRIPT_DIR%..\..
set WEBAPP_SRC=%BMA_ROOT%\servlets\servlet\src\main\webapp
set TOMCAT_HOME=%1
if "%TOMCAT_HOME%"=="" set TOMCAT_HOME=C:\Program Files\Apache Software Foundation\Tomcat 11.0
if "%TOMCAT_HOME%"=="" set TOMCAT_HOME=%CATALINA_HOME%
set CONTEXT=brarner.m.alete
set DEPLOY_DIR=%TOMCAT_HOME%\webapps\%CONTEXT%

echo ═══════════════════════════════════════════════════════════════
echo  Brarner.M.Alete™ — Local Deploy (Windows)
echo  Target: %DEPLOY_DIR%
echo ═══════════════════════════════════════════════════════════════

if not exist "%WEBAPP_SRC%" (
    echo [!] Webapp source not found: %WEBAPP_SRC%
    pause
    exit /b 1
)

if not exist "%TOMCAT_HOME%\webapps" (
    echo [!] Tomcat not found at: %TOMCAT_HOME%
    echo     Set CATALINA_HOME or pass path as argument.
    pause
    exit /b 1
)

echo [*] Deploying...
if exist "%DEPLOY_DIR%" rmdir /s /q "%DEPLOY_DIR%"
xcopy /s /e /i /q "%WEBAPP_SRC%" "%DEPLOY_DIR%"

REM Copy MySQL connector
if exist "%BMA_ROOT%\lib\mysql-connector-j-*.jar" (
    copy "%BMA_ROOT%\lib\mysql-connector-j-*.jar" "%DEPLOY_DIR%\WEB-INF\lib\" >nul
    echo [*] MySQL connector copied.
)

echo.
echo [✓] Deployed to: %DEPLOY_DIR%
echo     URL: http://localhost:8080/%CONTEXT%/
echo     Pages: index.jsp, species.jsp, postal.jsp, art.jsp, science.jsp, status.jsp
pause
