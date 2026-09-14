@echo off
REM Nsa — Deploy Local (Windows)
REM Usage: install\windows\deploy-local.bat [tomcat_home]
setlocal

set SCRIPT_DIR=%~dp0
set MOD_ROOT=%SCRIPT_DIR%..\..set NWE_ROOT=%SCRIPT_DIR%..\..\..\..\..
set TOMCAT_HOME=%1
if "%TOMCAT_HOME%"=="" set TOMCAT_HOME=C:\Program Files\Apache Software Foundation\Tomcat 10.1
set WEBAPP_SRC=%MOD_ROOT%\servlets\servlet\src\main\webapp
set DEPLOY_DIR=%TOMCAT_HOME%\webapps\california-nsa

echo ═══════════════════════════════════════════════════════════════
echo  Nsa — Deploy Local (Windows)
echo  Target: %DEPLOY_DIR%
echo ═══════════════════════════════════════════════════════════════

if not exist "%TOMCAT_HOME%\webapps" (
    echo [FAIL] Tomcat not found at: %TOMCAT_HOME%
    echo        Set TOMCAT_HOME or pass path as argument
    pause & exit /b 1
)

if exist "%DEPLOY_DIR%" rmdir /s /q "%DEPLOY_DIR%"
mkdir "%DEPLOY_DIR%\WEB-INF\lib"
xcopy /e /q "%WEBAPP_SRC%\*" "%DEPLOY_DIR%\"

set JDBC_JAR=
for %%f in ("%NWE_ROOT%\modules\black\presidential\Brarner.M.Alete\jars\mysql-connector-j-*.jar") do set JDBC_JAR=%%f
if "%JDBC_JAR%"=="" for %%f in ("%NWE_ROOT%\jars\mysql\mysql-connector-j-*.jar") do set JDBC_JAR=%%f
if not "%JDBC_JAR%"=="" (
    copy "%JDBC_JAR%" "%DEPLOY_DIR%\WEB-INF\lib\"
    echo [*] JDBC: %JDBC_JAR%
) else (
    echo [!] WARNING: mysql-connector-j not found
)

echo [OK] Deployed: http://localhost:8080/california-nsa/
echo ═══════════════════════════════════════════════════════════════
pause
endlocal
