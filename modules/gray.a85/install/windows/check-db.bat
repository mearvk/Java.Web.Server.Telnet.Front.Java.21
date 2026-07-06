@echo off
REM Gray A85 — Database Population Check (Windows)
REM Usage: install\windows\check-db.bat
setlocal

set SCRIPT_DIR=%~dp0
set MOD_ROOT=%SCRIPT_DIR%..\..set DB_PROPS=%MOD_ROOT%\servlets\servlet\src\main\webapp\WEB-INF\db.properties

for /f "tokens=2 delims==" %%a in ('findstr "^db.user=" "%DB_PROPS%"') do set DB_USER=%%a
for /f "tokens=2 delims==" %%a in ('findstr "^db.password=" "%DB_PROPS%"') do set DB_PASS=%%a
for /f "tokens=2 delims==" %%a in ('findstr "^db.url=" "%DB_PROPS%"') do set DB_URL=%%a
set DB_NAME=nwe_gray85_registry
set DB_HOST=127.0.0.1

echo ═══════════════════════════════════════════════════════════════
echo  Gray A85 — Database Population Check
echo  Database: %DB_NAME% @ %DB_HOST%
echo  Time:     %date% %time%
echo ═══════════════════════════════════════════════════════════════
echo.

mysql -u%DB_USER% -p%DB_PASS% -h%DB_HOST% -e "USE %DB_NAME%" 2>nul
if errorlevel 1 (
    echo [FAIL] Cannot connect to '%DB_NAME%'
    pause & exit /b 1
)

echo Tables:
echo.
mysql -u%DB_USER% -p%DB_PASS% -h%DB_HOST% %DB_NAME% -N -B -e "SELECT TABLE_NAME, TABLE_ROWS FROM information_schema.TABLES WHERE TABLE_SCHEMA='%DB_NAME%' ORDER BY TABLE_NAME;"
echo.
echo ═══════════════════════════════════════════════════════════════
pause
endlocal
