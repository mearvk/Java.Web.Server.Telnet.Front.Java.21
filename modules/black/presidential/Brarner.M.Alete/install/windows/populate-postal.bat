@echo off
REM Brarner.M.Alete™ — Populate Postal Database (Windows)
REM Usage: install\windows\populate-postal.bat
setlocal enabledelayedexpansion

set SCRIPT_DIR=%~dp0
set BMA_ROOT=%SCRIPT_DIR%..\..
set DB_PROPS=%BMA_ROOT%\servlets\servlet\src\main\webapp\WEB-INF\db.properties
set DATA_CSV=%BMA_ROOT%\data\postal\us-zip-codes.csv

for /f "tokens=2 delims==" %%a in ('findstr "db.user=" "%DB_PROPS%"') do set DB_USER=%%a
for /f "tokens=2 delims==" %%a in ('findstr "db.password=" "%DB_PROPS%"') do set DB_PASS=%%a

set MYSQL_CMD=mysql -u%DB_USER% -p%DB_PASS%

echo ═══════════════════════════════════════════════════════════════
echo  Brarner.M.Alete™ — Populate Postal Database
echo ═══════════════════════════════════════════════════════════════

%MYSQL_CMD% BrarnerScience -e "ALTER TABLE postal ADD COLUMN IF NOT EXISTS latitude DECIMAL(9,6) AFTER county; ALTER TABLE postal ADD COLUMN IF NOT EXISTS longitude DECIMAL(9,6) AFTER latitude;" 2>nul

if not exist "%DATA_CSV%" (
    echo [WARN] No postal CSV found: %DATA_CSV%
    exit /b 1
)

set TMP_SQL=%TEMP%\bma-postal.sql
echo USE BrarnerScience; > "%TMP_SQL%"
echo TRUNCATE TABLE postal; >> "%TMP_SQL%"

set COUNT=0
for /f "skip=1 usebackq tokens=1-6 delims=," %%a in ("%DATA_CSV%") do (
    echo INSERT INTO postal(zip_code,city,state,county,latitude,longitude) VALUES('%%a','%%b','%%c','%%d',%%e,%%f); >> "%TMP_SQL%"
    set /a COUNT+=1
)

%MYSQL_CMD% < "%TMP_SQL%"
del "%TMP_SQL%"
echo [OK] postal table: %COUNT% rows
echo ═══════════════════════════════════════════════════════════════
endlocal
