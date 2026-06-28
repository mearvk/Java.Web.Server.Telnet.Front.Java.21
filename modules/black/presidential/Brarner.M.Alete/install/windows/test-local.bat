@echo off
REM Brarner.M.Alete™ — Test Local (Windows)
REM Usage: install\windows\test-local.bat [port]
setlocal

set PORT=%1
if "%PORT%"=="" set PORT=8080
set BASE=http://localhost:%PORT%/brarner.m.alete

echo ═══════════════════════════════════════════════════════════════
echo  Brarner.M.Alete™ — Local Connectivity Test
echo  Base URL: %BASE%
echo ═══════════════════════════════════════════════════════════════
echo.

echo [*] Testing pages...
curl -s -o nul -w "  [%%{http_code}] index.jsp" "%BASE%/index.jsp" & echo.
curl -s -o nul -w "  [%%{http_code}] species.jsp" "%BASE%/species.jsp" & echo.
curl -s -o nul -w "  [%%{http_code}] postal.jsp" "%BASE%/postal.jsp" & echo.
curl -s -o nul -w "  [%%{http_code}] art.jsp" "%BASE%/art.jsp" & echo.
curl -s -o nul -w "  [%%{http_code}] science.jsp" "%BASE%/science.jsp" & echo.
curl -s -o nul -w "  [%%{http_code}] status.jsp" "%BASE%/status.jsp" & echo.

echo.
echo [*] Testing static resources...
curl -s -o nul -w "  [%%{http_code}] css/style.css" "%BASE%/css/style.css" & echo.
curl -s -o nul -w "  [%%{http_code}] config.xml" "%BASE%/config.xml" & echo.

echo.
echo ═══════════════════════════════════════════════════════════════
endlocal
