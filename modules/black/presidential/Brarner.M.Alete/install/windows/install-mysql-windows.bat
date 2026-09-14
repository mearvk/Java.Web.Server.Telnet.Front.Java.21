@echo off
REM Brarner.M.Alete™ — Install MySQL + Create Tables (Windows)
REM Downloads MySQL installer if not present, creates BrarnerScience DB and all tables.
REM Usage: Run as Administrator: install\windows\install-mysql-windows.bat

echo ═══════════════════════════════════════════════════════════════
echo  Brarner.M.Alete™ — MySQL Install (Windows)
echo ═══════════════════════════════════════════════════════════════

REM Check for mysql
where mysql >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [*] MySQL not found in PATH.
    echo     Download MySQL Community Server from:
    echo     https://dev.mysql.com/downloads/mysql/
    echo.
    echo     Or install via winget:
    echo     winget install Oracle.MySQL
    echo.
    echo     After installing, add MySQL bin to PATH and re-run this script.
    pause
    exit /b 1
)

echo [*] MySQL found: 
mysql --version

REM Prompt for credentials
set /p DB_USER="MySQL admin username [root]: " || set DB_USER=root
set /p DB_PASS="MySQL admin password: "

REM Create database and configure root for JDBC
echo [*] Creating database and configuring root access...
mysql -u%DB_USER% -p%DB_PASS% -e "CREATE DATABASE IF NOT EXISTS BrarnerScience CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci; ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$$Ironman1'; FLUSH PRIVILEGES;"

if %ERRORLEVEL% NEQ 0 (
    echo [FAIL] Could not connect to MySQL. Check credentials.
    pause
    exit /b 1
)

REM Create tables
echo [*] Creating tables...
mysql -u%DB_USER% -p%DB_PASS% BrarnerScience < "%~dp0create-tables.sql"

echo.
echo [OK] All tables created.
mysql -u%DB_USER% -p%DB_PASS% -e "USE BrarnerScience; SHOW TABLES;"

echo.
echo ═══════════════════════════════════════════════════════════════
echo  [✓] MySQL setup complete
echo      User: root / $$Ironman1
echo      Database: BrarnerScience
echo      Next: Run populate-science-db.bat
echo ═══════════════════════════════════════════════════════════════
pause
