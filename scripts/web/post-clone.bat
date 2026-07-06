@echo off
REM NitroWebExpress™ — Post-Clone Setup (Windows)
REM Run as Administrator after cloning the repository.
REM Usage: scripts\web\post-clone.bat
setlocal

set SCRIPT_DIR=%~dp0
set PROJECT_ROOT=%SCRIPT_DIR%..\..

echo ═══════════════════════════════════════════════════════════════
echo  NitroWebExpress™ — Post-Clone Setup (Windows)
echo ═══════════════════════════════════════════════════════════════

REM 1. Check Java
java -version 2>nul | findstr "21 22 23" >nul
if errorlevel 1 (
    echo [!] Java 21+ required. Download: https://adoptium.net/
    echo     Install and add to PATH, then re-run this script.
    pause
    exit /b 1
)
echo [OK] Java found

REM 2. Check MySQL
where mysql >nul 2>&1
if errorlevel 1 (
    echo [!] MySQL required. Download: https://dev.mysql.com/downloads/installer/
    echo     Install MySQL 8.x and add bin\ to PATH.
    pause
    exit /b 1
)
echo [OK] MySQL found

REM 3. Configure MySQL root
mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH caching_sha2_password BY '$$Ironman1'; FLUSH PRIVILEGES;" 2>nul
echo [OK] MySQL root configured

REM 4. Check/Install Tomcat
set TOMCAT_HOME=%CATALINA_HOME%
if "%TOMCAT_HOME%"=="" set TOMCAT_HOME=C:\opt\tomcat
if not exist "%TOMCAT_HOME%\bin\catalina.bat" (
    echo [!] Tomcat not found at %TOMCAT_HOME%
    echo     Download: https://tomcat.apache.org/download-11.cgi
    echo     Extract to C:\opt\tomcat and set CATALINA_HOME
    pause
    exit /b 1
)
echo [OK] Tomcat: %TOMCAT_HOME%

REM 5. Setup module databases
echo [*] Setting up module databases...
where bash >nul 2>&1 && (
    bash "%PROJECT_ROOT%\california\fbi\servlets\setup-db.sh" 2>nul
    bash "%PROJECT_ROOT%\california\cia\servlets\setup-db.sh" 2>nul
    bash "%PROJECT_ROOT%\california\nsa\servlets\setup-db.sh" 2>nul
    bash "%PROJECT_ROOT%\north\carolina\duke\servlets\setup-db.sh" 2>nul
    bash "%PROJECT_ROOT%\north\carolina\library\servlets\setup-db.sh" 2>nul
    echo [OK] Databases created
) || (
    echo [WARN] bash not available - run setup-db.sh scripts manually via Git Bash
)

REM 6. Deploy all modules
echo.
call "%SCRIPT_DIR%deploy-all.bat"

REM 7. Start Tomcat
call "%TOMCAT_HOME%\bin\startup.bat"

REM 8. Register as scheduled task for reboot
schtasks /create /tn "NWE-Tomcat" /tr "\"%TOMCAT_HOME%\bin\startup.bat\"" /sc onstart /ru SYSTEM /f 2>nul
echo [OK] Tomcat registered to start on boot

echo.
echo ═══════════════════════════════════════════════════════════════
echo  Post-clone setup complete.
echo  All modules: http://localhost:8080/
echo ═══════════════════════════════════════════════════════════════
endlocal
