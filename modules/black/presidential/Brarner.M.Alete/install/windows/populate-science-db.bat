@echo off
REM Brarner.M.Alete™ — Populate Science Database (Windows)
REM Reads species config.xml files and inserts into BrarnerScience.animalia
REM Usage: install\windows\populate-science-db.bat

echo ═══════════════════════════════════════════════════════════════
echo  Brarner.M.Alete™ — Populate Science Database (Windows)
echo ═══════════════════════════════════════════════════════════════

set SCRIPT_DIR=%~dp0
set BMA_ROOT=%SCRIPT_DIR%..\..
set SPECIES_DIR=%BMA_ROOT%\source\species
set TMP_SQL=%TEMP%\bma-populate.sql

REM Read credentials from db.properties
set DB_PROPS=%BMA_ROOT%\servlets\servlet\src\main\webapp\WEB-INF\db.properties
if not exist "%DB_PROPS%" (
    echo [FAIL] db.properties not found. Run install-mysql-windows.bat first.
    pause
    exit /b 1
)

for /f "tokens=1,* delims==" %%A in ('findstr "db.user" "%DB_PROPS%"') do set DB_USER=%%B
for /f "tokens=1,* delims==" %%A in ('findstr "db.password" "%DB_PROPS%"') do set DB_PASS=%%B

echo [*] User: %DB_USER%
echo [*] Scanning config.xml files...

echo USE BrarnerScience; > "%TMP_SQL%"
echo TRUNCATE TABLE animalia; >> "%TMP_SQL%"
echo INSERT INTO animalia (kingdom, phylum, subphylum, class_name, subclass, order_name, suborder, infraorder, family_name) VALUES >> "%TMP_SQL%"

set COUNT=0
set FIRST=1

for /r "%SPECIES_DIR%" %%F in (config.xml) do (
    set /a COUNT+=1
    REM Use PowerShell to extract XML fields
    for /f "delims=" %%K in ('powershell -NoProfile -Command "[xml]$x=Get-Content '%%F'; $x.SelectSingleNode('//kingdom').InnerText"') do set KINGDOM=%%K
    for /f "delims=" %%P in ('powershell -NoProfile -Command "[xml]$x=Get-Content '%%F'; $x.SelectSingleNode('//phylum').InnerText"') do set PHYLUM=%%P
    for /f "delims=" %%S in ('powershell -NoProfile -Command "[xml]$x=Get-Content '%%F'; $x.SelectSingleNode('//subphylum').InnerText"') do set SUBPHYLUM=%%S
    for /f "delims=" %%C in ('powershell -NoProfile -Command "[xml]$x=Get-Content '%%F'; $x.SelectSingleNode('//class-name').InnerText"') do set CLASS=%%C
    for /f "delims=" %%O in ('powershell -NoProfile -Command "[xml]$x=Get-Content '%%F'; $x.SelectSingleNode('//order').InnerText"') do set ORDER=%%O
    for /f "delims=" %%M in ('powershell -NoProfile -Command "[xml]$x=Get-Content '%%F'; $x.SelectSingleNode('//family').InnerText"') do set FAMILY=%%M

    if !FIRST!==1 (
        set FIRST=0
    ) else (
        echo , >> "%TMP_SQL%"
    )
    echo ('%KINGDOM%','%PHYLUM%','%SUBPHYLUM%','%CLASS%','','%ORDER%','','','%FAMILY%') >> "%TMP_SQL%"
)

echo ; >> "%TMP_SQL%"

echo [*] Inserting %COUNT% records...
mysql -u%DB_USER% -p%DB_PASS% < "%TMP_SQL%"

echo [OK] animalia populated with %COUNT% records.
mysql -u%DB_USER% -p%DB_PASS% -e "USE BrarnerScience; SELECT kingdom, COUNT(*) AS total FROM animalia GROUP BY kingdom;"

del "%TMP_SQL%" 2>nul
echo.
echo [✓] Done.
pause
