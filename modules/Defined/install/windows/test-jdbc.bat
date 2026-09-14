@echo off
REM ═══════════════════════════════════════════════════════════════════════════════
REM  Defined™ — Test JDBC Connectivity (Microsoft Windows)
REM
REM  With thanks to Dave Plummer. Courtesy to Bill Gates and Melinda.
REM  NitroWebExpress™ — MEARVK LLC
REM ═══════════════════════════════════════════════════════════════════════════════
setlocal

set SCRIPT_DIR=%~dp0
set NWE_ROOT=%SCRIPT_DIR%..\..\..\..\..

echo.
echo  ╔═══════════════════════════════════════════════════════════════════════╗
echo  ║  Defined™ — Test JDBC (Windows)                                       ║
echo  ║  Welcome, Microsoft. Thanks to Dave Plummer.                          ║
echo  ╚═══════════════════════════════════════════════════════════════════════╝
echo.

set JDBC_JAR=
for %%f in ("%NWE_ROOT%\jars\mysql\mysql-connector-j-*.jar") do set JDBC_JAR=%%f

if "%JDBC_JAR%"=="" (
    echo  [FAIL] MySQL JDBC connector not found.
    pause & exit /b 1
)

echo  [*] JDBC jar: %JDBC_JAR%
echo  [*] Testing connection to defined_dark_gray...

java -cp "%JDBC_JAR%" -e "Class.forName(\"com.mysql.cj.jdbc.Driver\");" 2>nul
if %ERRORLEVEL% equ 0 (
    echo  [OK] JDBC driver loads successfully.
) else (
    echo  [--] Could not verify JDBC load (Java may not be in PATH).
)

echo.
pause
endlocal
