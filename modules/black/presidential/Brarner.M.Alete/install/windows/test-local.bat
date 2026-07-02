@echo off
REM Brarner.M.Alete™ — Test Local (Windows)
REM Usage: install\windows\test-local.bat [port]
setlocal

set PORT=%1
if "%PORT%"=="" set PORT=8080
set BMA_ROOT=%~dp0..\..
set BASE=http://localhost:%PORT%/brarner.m.alete

echo ═══════════════════════════════════════════════════════════════
echo  Brarner.M.Alete™ — Local Connectivity Test
echo  Base URL: %BASE%
echo ═══════════════════════════════════════════════════════════════
echo.

echo [*] Testing pages...
for %%f in (%BMA_ROOT%\servlets\servlet\src\main\webapp\*.jsp) do (
    curl -s -o nul -w "  [%%{http_code}] %%~nxf" "%BASE%/%%~nxf" & echo.
)

echo.
echo [*] Testing static resources...
curl -s -o nul -w "  [%%{http_code}] css/style.css" "%BASE%/css/style.css" & echo.
curl -s -o nul -w "  [%%{http_code}] config.xml" "%BASE%/config.xml" & echo.

echo.
echo ═══════════════════════════════════════════════════════════════
endlocal
