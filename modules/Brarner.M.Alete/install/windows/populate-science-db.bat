@echo off
REM Brarner.M.Alete™ — Populate Science/Animalia Database (Windows)
REM Usage: install\windows\populate-science-db.bat
setlocal enabledelayedexpansion

set SCRIPT_DIR=%~dp0
set BMA_ROOT=%SCRIPT_DIR%..\..
set DB_PROPS=%BMA_ROOT%\servlets\servlet\src\main\webapp\WEB-INF\db.properties

for /f "tokens=2 delims==" %%a in ('findstr "db.user=" "%DB_PROPS%"') do set DB_USER=%%a
for /f "tokens=2 delims==" %%a in ('findstr "db.password=" "%DB_PROPS%"') do set DB_PASS=%%a

set MYSQL_CMD=mysql -u%DB_USER% -p%DB_PASS%

echo ═══════════════════════════════════════════════════════════════
echo  Brarner.M.Alete™ — Populate Science Database
echo ═══════════════════════════════════════════════════════════════

REM Create tables
%MYSQL_CMD% < "%BMA_ROOT%\install\macos\create-tables.sql" 2>nul

REM Build SQL from species config.xml files
set SPECIES_DIR=%BMA_ROOT%\source\species
set TMP_SQL=%TEMP%\bma-animalia.sql

echo USE BrarnerScience; > "%TMP_SQL%"
echo TRUNCATE TABLE animalia; >> "%TMP_SQL%"

set COUNT=0
for /r "%SPECIES_DIR%" %%f in (config.xml) do (
    set "KINGDOM=" & set "PHYLUM=" & set "SUBPHYLUM=" & set "CLASS=" & set "SUBCLASS="
    set "ORDER=" & set "SUBORDER=" & set "INFRAORDER=" & set "FAMILY="
    for /f "tokens=*" %%l in ('type "%%f" 2^>nul') do (
        echo %%l | findstr /c:"<kingdom>" >nul && for /f "tokens=2 delims=<>" %%v in ("%%l") do set "KINGDOM=%%v"
        echo %%l | findstr /c:"<phylum>" >nul && for /f "tokens=2 delims=<>" %%v in ("%%l") do set "PHYLUM=%%v"
        echo %%l | findstr /c:"<subphylum>" >nul && for /f "tokens=2 delims=<>" %%v in ("%%l") do set "SUBPHYLUM=%%v"
        echo %%l | findstr /c:"<class-name>" >nul && for /f "tokens=2 delims=<>" %%v in ("%%l") do set "CLASS=%%v"
        echo %%l | findstr /c:"<subclass>" >nul && for /f "tokens=2 delims=<>" %%v in ("%%l") do set "SUBCLASS=%%v"
        echo %%l | findstr /c:"<order>" >nul && for /f "tokens=2 delims=<>" %%v in ("%%l") do set "ORDER=%%v"
        echo %%l | findstr /c:"<suborder>" >nul && for /f "tokens=2 delims=<>" %%v in ("%%l") do set "SUBORDER=%%v"
        echo %%l | findstr /c:"<infraorder>" >nul && for /f "tokens=2 delims=<>" %%v in ("%%l") do set "INFRAORDER=%%v"
        echo %%l | findstr /c:"<family>" >nul && for /f "tokens=2 delims=<>" %%v in ("%%l") do set "FAMILY=%%v"
    )
    echo INSERT INTO animalia(kingdom,phylum,subphylum,class_name,subclass,order_name,suborder,infraorder,family_name) VALUES('!KINGDOM!','!PHYLUM!','!SUBPHYLUM!','!CLASS!','!SUBCLASS!','!ORDER!','!SUBORDER!','!INFRAORDER!','!FAMILY!'); >> "%TMP_SQL%"
    set /a COUNT+=1
)

%MYSQL_CMD% BrarnerScience < "%TMP_SQL%"
del "%TMP_SQL%"
echo [OK] animalia: %COUNT% records inserted
echo ═══════════════════════════════════════════════════════════════
endlocal
