@echo off
REM ═══════════════════════════════════════════════════════════════════════════════
REM NitroWebExpress™ — Start Backend Modules (Windows)
REM Starts Main.java with G1GC, 4GB heap.
REM Usage: scripts\start-backends.bat
REM ═══════════════════════════════════════════════════════════════════════════════
setlocal enabledelayedexpansion

set "PROJECT_ROOT=%~dp0.."
pushd "%PROJECT_ROOT%"
set "PROJECT_ROOT=%CD%"
popd

set "OUT=%PROJECT_ROOT%\out"
set "PID_DIR=%PROJECT_ROOT%\data"
set "PID_FILE=%PID_DIR%\nwe-main.pid"
set "LOG_FILE=%PROJECT_ROOT%\logging\nwe-main.log"

if not exist "%PID_DIR%" mkdir "%PID_DIR%"
if not exist "%PROJECT_ROOT%\logging" mkdir "%PROJECT_ROOT%\logging"

REM ── Check if already running ────────────────────────────────────────────────
if exist "%PID_FILE%" (
    set /p OLD_PID=<"%PID_FILE%"
    tasklist /FI "PID eq !OLD_PID!" 2>nul | findstr "!OLD_PID!" >nul && (
        echo [*] NWE Main already running ^(PID !OLD_PID!^)
        echo     Stop first: scripts\shutdown-backends.bat
        exit /b 0
    )
    del "%PID_FILE%" 2>nul
)

REM ── Build classpath ─────────────────────────────────────────────────────────
set "MYSQL_JAR=%PROJECT_ROOT%\jars\mysql\mysql-connector-j-9.7.0.jar"
set "LANTERNA_JAR=%PROJECT_ROOT%\jars\lanterna-3.1.5.jar"
set "CP=%OUT%;%MYSQL_JAR%;%LANTERNA_JAR%"
for /r "%PROJECT_ROOT%\jars\djl" %%J in (*.jar) do set "CP=!CP!;%%J"
for /r "%PROJECT_ROOT%\jars\jpcap" %%J in (*.jar) do set "CP=!CP!;%%J"

echo [*] Starting NitroWebExpress™ backends...
echo     Classpath: %OUT% + jars\*
echo     JVM: G1GC, 4GB heap, Java 21
echo.

REM ── Start in background ─────────────────────────────────────────────────────
start "NitroWebExpress-Backend" /B javaw -server -XX:+UseG1GC -Xmx4g -Xms1g ^
    -Duser.dir="%PROJECT_ROOT%" ^
    -Djava.util.logging.config.file="%PROJECT_ROOT%\configuration\logging.properties" ^
    -cp "%CP%" Main > "%LOG_FILE%" 2>&1

REM Give it a moment to start
timeout /t 3 /nobreak >nul

REM ── Capture PID ─────────────────────────────────────────────────────────────
for /f "tokens=2" %%P in ('tasklist /FI "WINDOWTITLE eq NitroWebExpress-Backend" /NH 2^>nul ^| findstr "java"') do (
    set "JAVA_PID=%%P"
)

REM Fallback: find newest java process
if not defined JAVA_PID (
    for /f "tokens=2" %%P in ('wmic process where "name='javaw.exe' and commandline like '%%Main%%'" get processid /format:list 2^>nul ^| findstr "ProcessId"') do (
        set "JAVA_PID=%%P"
    )
)

if defined JAVA_PID (
    echo !JAVA_PID!> "%PID_FILE%"
    echo [OK] NWE Main started ^(PID !JAVA_PID!^)
    echo     PID file: %PID_FILE%
    echo     Log: %LOG_FILE%
) else (
    echo [WARN] Started but could not capture PID — check log:
    echo        %LOG_FILE%
)

echo.
echo [*] Verifying ports ^(waiting 5 seconds^)...
timeout /t 5 /nobreak >nul

set PORTS_UP=0
for %%P in (49152,20000,2000,5512,6682) do (
    powershell -NoProfile -Command "try { $t = New-Object Net.Sockets.TcpClient; $t.Connect('localhost',%%P); $t.Close(); exit 0 } catch { exit 1 }" 2>nul && (
        echo   [OK] Port %%P listening
        set /a PORTS_UP+=1
    ) || (
        echo   [--] Port %%P not yet listening
    )
)
echo   Ports up: %PORTS_UP% / 5
echo.
endlocal
