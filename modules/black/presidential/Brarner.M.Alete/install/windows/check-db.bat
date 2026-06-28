@echo off
REM Brarner.M.Alete™ — Database Population Check (Windows)
REM Usage: install\windows\check-db.bat

set DB_USER=root
set DB_PASS=$$Ironman1
set DB_NAME=BrarnerScience
set DB_HOST=localhost

echo ═══════════════════════════════════════════════════════════════
echo  Brarner.M.Alete™ — Database Population Check
echo  Database: %DB_NAME% @ %DB_HOST%
echo  Time:     %date% %time%
echo ═══════════════════════════════════════════════════════════════
echo.

mysql -u%DB_USER% -p%DB_PASS% -h%DB_HOST% -e "USE %DB_NAME%" 2>nul
if errorlevel 1 (
    echo [FAIL] Database '%DB_NAME%' does not exist!
    exit /b 1
)

echo Tables:
echo.
mysql -u%DB_USER% -p%DB_PASS% -h%DB_HOST% %DB_NAME% -N -B -e "SELECT TABLE_NAME, TABLE_ROWS FROM information_schema.TABLES WHERE TABLE_SCHEMA='%DB_NAME%' ORDER BY TABLE_NAME;"
echo.
echo ═══════════════════════════════════════════════════════════════
