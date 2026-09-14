@echo off
REM Black Belt — Local Connectivity Test (Windows)
REM Usage: install\windows\test-local.bat [port]
setlocal

set PORT=%1
if "%PORT%"=="" set PORT=8080
set BASE=http://localhost:%PORT%/blackbelt

echo ═══════════════════════════════════════════════════════════════
echo  Black Belt — Local Connectivity Test
echo  Base URL: %BASE%
echo ═══════════════════════════════════════════════════════════════
echo.

echo [*] Testing pages...
curl -s -o nul -w "  [%%{http_code}] index.jsp\n" "%BASE%/index.jsp"
curl -s -o nul -w "  [%%{http_code}] ask.jsp\n" "%BASE%/ask.jsp"
curl -s -o nul -w "  [%%{http_code}] belts.jsp\n" "%BASE%/belts.jsp"
curl -s -o nul -w "  [%%{http_code}] history.jsp\n" "%BASE%/history.jsp"
curl -s -o nul -w "  [%%{http_code}] css/style.css\n" "%BASE%/css/style.css"

echo.
echo ═══════════════════════════════════════════════════════════════
pause
endlocal
