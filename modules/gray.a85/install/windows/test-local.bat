@echo off
REM Gray A85 — Local Connectivity Test (Windows)
REM Usage: install\windows\test-local.bat [port]
setlocal

set PORT=%1
if "%PORT%"=="" set PORT=8080
set BASE=http://localhost:%PORT%/gray85-registry

echo ═══════════════════════════════════════════════════════════════
echo  Gray A85 — Local Connectivity Test
echo  Base URL: %BASE%
echo ═══════════════════════════════════════════════════════════════
echo.

echo [*] Testing pages...
curl -s -o nul -w "  [%%{http_code}] index.jsp\n" "%BASE%/index.jsp"
curl -s -o nul -w "  [%%{http_code}] bindings.jsp\n" "%BASE%/bindings.jsp"
curl -s -o nul -w "  [%%{http_code}] creme.jsp\n" "%BASE%/creme.jsp"
curl -s -o nul -w "  [%%{http_code}] leases.jsp\n" "%BASE%/leases.jsp"
curl -s -o nul -w "  [%%{http_code}] status.jsp\n" "%BASE%/status.jsp"
curl -s -o nul -w "  [%%{http_code}] css/style.css\n" "%BASE%/css/style.css"

echo.
echo ═══════════════════════════════════════════════════════════════
pause
endlocal
