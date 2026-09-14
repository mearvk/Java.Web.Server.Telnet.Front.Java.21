@echo off
REM Brarner.M.Alete™ — Populate SSA Database (Windows)
REM Usage: install\windows\populate-ssa.bat
setlocal enabledelayedexpansion

set SCRIPT_DIR=%~dp0
set BMA_ROOT=%SCRIPT_DIR%..\..
set DB_PROPS=%BMA_ROOT%\servlets\servlet\src\main\webapp\WEB-INF\db.properties
set DATA_CSV=%BMA_ROOT%\data\ssa\ssa-offices.csv

for /f "tokens=2 delims==" %%a in ('findstr "db.user=" "%DB_PROPS%"') do set DB_USER=%%a
for /f "tokens=2 delims==" %%a in ('findstr "db.password=" "%DB_PROPS%"') do set DB_PASS=%%a

set MYSQL_CMD=mysql -u%DB_USER% -p%DB_PASS%

echo ═══════════════════════════════════════════════════════════════
echo  Brarner.M.Alete™ — Populate SSA Database
echo ═══════════════════════════════════════════════════════════════

%MYSQL_CMD% BrarnerScience -e "CREATE TABLE IF NOT EXISTS ssa_offices (id BIGINT AUTO_INCREMENT PRIMARY KEY, office_name VARCHAR(255), address VARCHAR(500), city VARCHAR(100), state VARCHAR(50), zip_code VARCHAR(10), phone VARCHAR(30), office_type VARCHAR(50), INDEX idx_state(state), INDEX idx_city(city));" 2>nul

if not exist "%DATA_CSV%" (
    echo [WARN] No SSA CSV found: %DATA_CSV%
    exit /b 1
)

set TMP_SQL=%TEMP%\bma-ssa.sql
echo USE BrarnerScience; > "%TMP_SQL%"
echo TRUNCATE TABLE ssa_offices; >> "%TMP_SQL%"

set COUNT=0
for /f "skip=1 usebackq tokens=1-8 delims=," %%a in ("%DATA_CSV%") do (
    echo INSERT INTO ssa_offices(office_name,address,city,state,zip_code,phone,office_type) VALUES('%%a','%%b','%%c','%%d','%%e','%%f','%%g'); >> "%TMP_SQL%"
    set /a COUNT+=1
)

%MYSQL_CMD% < "%TMP_SQL%"
del "%TMP_SQL%"
echo [OK] ssa_offices: %COUNT% rows
echo ═══════════════════════════════════════════════════════════════
endlocal
