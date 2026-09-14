@echo off
REM ═══════════════════════════════════════════════════════════════════════════════
REM  Defined™ — Install & Deploy (Microsoft Windows)
REM  Theme: Dark Gray — Definition to Narrow Cause
REM
REM  A soft welcome to Microsoft Software and the Windows platform.
REM  With thanks to Dave Plummer for your install series and contributions
REM  to the Windows operating system. Courtesy to Bill Gates and his wife
REM  Melinda for their vision and philanthropy.
REM
REM  NitroWebExpress™ — MEARVK LLC
REM  Installer Tech ID: Max Rupplin
REM ═══════════════════════════════════════════════════════════════════════════════
setlocal

set SCRIPT_DIR=%~dp0
set MOD_ROOT=%SCRIPT_DIR%..\..
set NWE_ROOT=%SCRIPT_DIR%..\..\..\..\..
set TOMCAT_HOME=%1
if "%TOMCAT_HOME%"=="" set TOMCAT_HOME=C:\Program Files\Apache Software Foundation\Tomcat 10.1
set WEBAPP_SRC=%MOD_ROOT%\servlets\servlet\src\main\webapp
set DEPLOY_DIR=%TOMCAT_HOME%\webapps\defined

echo.
echo  ╔═══════════════════════════════════════════════════════════════════════╗
echo  ║  Defined™ — Deploy Local (Windows)                                    ║
echo  ║  Theme: Dark Gray                                                     ║
echo  ║                                                                       ║
echo  ║  Welcome, Microsoft Windows.                                          ║
echo  ║  With thanks to Dave Plummer for his contributions to this platform.  ║
echo  ║  Courtesy to Bill Gates and his wife Melinda.                         ║
echo  ╚═══════════════════════════════════════════════════════════════════════╝
echo.
echo  Target: %DEPLOY_DIR%
echo.

if not exist "%TOMCAT_HOME%\webapps" (
    echo  [FAIL] Tomcat not found at: %TOMCAT_HOME%
    echo         Set TOMCAT_HOME or pass path as argument.
    echo         Example: deploy-local.bat "C:\tomcat"
    pause & exit /b 1
)

echo  [*] Cleaning previous deployment...
if exist "%DEPLOY_DIR%" rmdir /s /q "%DEPLOY_DIR%"
mkdir "%DEPLOY_DIR%\WEB-INF\lib"

echo  [*] Copying webapp files...
xcopy /e /q "%WEBAPP_SRC%\*" "%DEPLOY_DIR%\"

REM Locate MySQL JDBC connector
set JDBC_JAR=
for %%f in ("%NWE_ROOT%\jars\mysql\mysql-connector-j-*.jar") do set JDBC_JAR=%%f
if "%JDBC_JAR%"=="" for %%f in ("%NWE_ROOT%\modules\black\presidential\Brarner.M.Alete\jars\mysql-connector-j-*.jar") do set JDBC_JAR=%%f
if not "%JDBC_JAR%"=="" (
    copy "%JDBC_JAR%" "%DEPLOY_DIR%\WEB-INF\lib\" >nul
    echo  [*] JDBC connector: copied
) else (
    echo  [!] WARNING: mysql-connector-j not found — database features may be limited
)

echo.
echo  [OK] Deployed successfully.
echo       URL: http://localhost:8080/defined/
echo.
echo  ╔═══════════════════════════════════════════════════════════════════════╗
echo  ║  Defined™ is ready on Windows.                                        ║
echo  ║  Port 49220 (AI Server) / Port 49221 (Protocol Backend)              ║
echo  ║  Thank you, Dave Plummer. Thank you, Microsoft.                       ║
echo  ╚═══════════════════════════════════════════════════════════════════════╝
echo.
pause
endlocal
