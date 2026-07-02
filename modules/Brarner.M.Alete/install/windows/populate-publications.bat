@echo off
REM Brarner.M.Alete™ — Populate Publications Database (Windows)
REM Usage: install\windows\populate-publications.bat
setlocal enabledelayedexpansion

set SCRIPT_DIR=%~dp0
set BMA_ROOT=%SCRIPT_DIR%..\..
set DB_PROPS=%BMA_ROOT%\servlets\servlet\src\main\webapp\WEB-INF\db.properties
set DATA_CSV=%BMA_ROOT%\data\publications\publications.csv

for /f "tokens=2 delims==" %%a in ('findstr "db.user=" "%DB_PROPS%"') do set DB_USER=%%a
for /f "tokens=2 delims==" %%a in ('findstr "db.password=" "%DB_PROPS%"') do set DB_PASS=%%a

set MYSQL_CMD=mysql -u%DB_USER% -p%DB_PASS%

echo ═══════════════════════════════════════════════════════════════
echo  Brarner.M.Alete™ — Populate Publications Database
echo ═══════════════════════════════════════════════════════════════

%MYSQL_CMD% BrarnerScience -e "ALTER TABLE publications ADD COLUMN IF NOT EXISTS abstract_text TEXT AFTER year_published;" 2>nul

if not exist "%DATA_CSV%" (
    echo [WARN] No publications CSV found: %DATA_CSV%
    exit /b 1
)

set TMP_SQL=%TEMP%\bma-pubs.sql
echo USE BrarnerScience; > "%TMP_SQL%"
echo TRUNCATE TABLE publications; >> "%TMP_SQL%"

set COUNT=0
for /f "skip=1 usebackq tokens=1-6 delims=," %%a in ("%DATA_CSV%") do (
    echo INSERT INTO publications(source_name,title,authors,doi,year_published,abstract_text) VALUES('%%a','%%b','%%c','%%d','%%e','%%f'); >> "%TMP_SQL%"
    set /a COUNT+=1
)

%MYSQL_CMD% < "%TMP_SQL%"
del "%TMP_SQL%"
echo [OK] publications table: %COUNT% rows
echo ═══════════════════════════════════════════════════════════════
endlocal
