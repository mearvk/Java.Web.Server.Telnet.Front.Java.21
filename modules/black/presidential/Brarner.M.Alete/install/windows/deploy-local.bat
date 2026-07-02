@echo off
REM Brarner.M.Alete™ — Deploy Local (Windows, Embedded Tomcat)
REM Usage: install\windows\deploy-local.bat [port]
setlocal

set SCRIPT_DIR=%~dp0
set BMA_ROOT=%SCRIPT_DIR%..\..
set PORT=%1
if "%PORT%"=="" set PORT=8080

set WEBAPP=%BMA_ROOT%\servlets\servlet\src\main\webapp
set JARS=%BMA_ROOT%\jars
set OUT=%BMA_ROOT%\out

echo ═══════════════════════════════════════════════════════════════
echo  Brarner.M.Alete™ — Deploy Local (port %PORT%)
echo ═══════════════════════════════════════════════════════════════

mkdir "%OUT%" 2>nul

echo [*] Compiling embedded Tomcat launcher...
javac -cp "%JARS%\*" -d "%OUT%" "%BMA_ROOT%\servlets\servlet\src\main\java\com\mearvk\servlet\BmaEmbeddedTomcat.java"
if errorlevel 1 (
    echo [FAIL] Compilation failed
    exit /b 1
)

echo [*] Starting Brarner.M.Alete on port %PORT%...
echo     URL: http://localhost:%PORT%/brarner.m.alete/
start "BMA Tomcat" java -cp "%OUT%;%JARS%\*" com.mearvk.servlet.BmaEmbeddedTomcat %PORT% "%WEBAPP%"

echo [OK] Server starting in background
echo ═══════════════════════════════════════════════════════════════
endlocal
