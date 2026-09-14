@echo off
REM Ae6E66 — Local Connectivity Test (Windows)
REM Usage: install\windows\test-local.bat [port]
setlocal

set PORT=%1
if "%PORT%"=="" set PORT=8080
set BASE=http://localhost:%PORT%/ae6e66

echo ═══════════════════════════════════════════════════════════════
echo  Ae6E66 — Local Connectivity Test
echo  Base URL: %BASE%
echo ═══════════════════════════════════════════════════════════════
echo.

echo [*] Testing pages...
curl -s -o nul -w "  [%%{http_code}] index.jsp\n" "%BASE%/index.jsp"
curl -s -o nul -w "  [%%{http_code}] contacts.jsp\n" "%BASE%/contacts.jsp"
curl -s -o nul -w "  [%%{http_code}] crawl.jsp\n" "%BASE%/crawl.jsp"
curl -s -o nul -w "  [%%{http_code}] sent.jsp\n" "%BASE%/sent.jsp"
curl -s -o nul -w "  [%%{http_code}] status.jsp\n" "%BASE%/status.jsp"
curl -s -o nul -w "  [%%{http_code}] css/style.css\n" "%BASE%/css/style.css"

echo.
echo ═══════════════════════════════════════════════════════════════
pause
endlocal
