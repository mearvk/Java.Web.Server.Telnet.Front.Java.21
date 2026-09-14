@echo off
REM Futures — Local Connectivity Test (Windows)
REM Usage: install\windows\test-local.bat [port]
setlocal

set PORT=%1
if "%PORT%"=="" set PORT=8080
set BASE=http://localhost:%PORT%/futures

echo ═══════════════════════════════════════════════════════════════
echo  Futures — Local Connectivity Test
echo  Base URL: %BASE%
echo ═══════════════════════════════════════════════════════════════
echo.

echo [*] Testing pages...
curl -s -o nul -w "  [%%{http_code}] index.jsp\n" "%BASE%/index.jsp"
curl -s -o nul -w "  [%%{http_code}] pipeline.jsp\n" "%BASE%/pipeline.jsp"
curl -s -o nul -w "  [%%{http_code}] safety.jsp\n" "%BASE%/safety.jsp"
curl -s -o nul -w "  [%%{http_code}] status.jsp\n" "%BASE%/status.jsp"
curl -s -o nul -w "  [%%{http_code}] training.jsp\n" "%BASE%/training.jsp"
curl -s -o nul -w "  [%%{http_code}] css/style.css\n" "%BASE%/css/style.css"

echo.
echo ═══════════════════════════════════════════════════════════════
pause
endlocal
