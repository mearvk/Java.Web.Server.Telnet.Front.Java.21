@echo off
REM Fbi — Local Connectivity Test (Windows)
REM Usage: install\windows\test-local.bat [port]
setlocal

set PORT=%1
if "%PORT%"=="" set PORT=8080
set BASE=http://localhost:%PORT%/california-fbi

echo ═══════════════════════════════════════════════════════════════
echo  Fbi — Local Connectivity Test
echo  Base URL: %BASE%
echo ═══════════════════════════════════════════════════════════════
echo.

echo [*] Testing pages...
curl -s -o nul -w "  [%%{http_code}] index.jsp\n" "%BASE%/index.jsp"
curl -s -o nul -w "  [%%{http_code}] report.jsp\n" "%BASE%/report.jsp"
curl -s -o nul -w "  [%%{http_code}] search.jsp\n" "%BASE%/search.jsp"
curl -s -o nul -w "  [%%{http_code}] status.jsp\n" "%BASE%/status.jsp"
curl -s -o nul -w "  [%%{http_code}] css/style.css\n" "%BASE%/css/style.css"

echo.
echo ═══════════════════════════════════════════════════════════════
pause
endlocal
