@echo off
REM ═══════════════════════════════════════════════════════════════════════════════
REM NitroWebExpress™ — Post-Clone Setup (Windows)
REM Run as Administrator after cloning the repository.
REM Reads Tomcat version/path from configuration\nwe-config.xml <web-servers>
REM Usage: scripts\web\post-clone.bat
REM ═══════════════════════════════════════════════════════════════════════════════
setlocal enabledelayedexpansion

set "SCRIPT_DIR=%~dp0"
set "PROJECT_ROOT=%SCRIPT_DIR%..\.."
pushd "%PROJECT_ROOT%"
set "PROJECT_ROOT=%CD%"
popd

echo.
echo ═══════════════════════════════════════════════════════════════
echo  NitroWebExpress™ — Post-Clone Setup (Windows)
echo ═══════════════════════════════════════════════════════════════
echo.

REM ── 1. Check Java 21+ ──────────────────────────────────────────────────────
java -version 2>&1 | findstr /C:"21." /C:"22." /C:"23." >nul 2>&1
if errorlevel 1 (
    echo [FAIL] Java 21+ required. Download: https://adoptium.net/
    echo        Install and add to PATH, then re-run this script.
    pause
    exit /b 1
)
echo [OK] Java 21+ found

REM ── 2. Check MySQL ─────────────────────────────────────────────────────────
where mysql >nul 2>&1
if errorlevel 1 (
    echo [FAIL] MySQL required. Download: https://dev.mysql.com/downloads/installer/
    echo        Install MySQL 8.x and add bin\ to PATH.
    pause
    exit /b 1
)
echo [OK] MySQL found

REM ── 3. Read Tomcat config from nwe-config.xml ──────────────────────────────
set "NWE_CONFIG=%PROJECT_ROOT%\configuration\nwe-config.xml"
set "TOMCAT_VERSION=11.0.2"
set "TOMCAT_HOME=C:\opt\apache-tomcat-11.0.2"

if exist "%NWE_CONFIG%" (
    REM Extract version from <tomcat> section
    for /f "tokens=2 delims=<>" %%A in ('powershell -NoProfile -Command "([xml](Get-Content '%NWE_CONFIG%')).SelectSingleNode('//web-servers/tomcat/version').InnerText" 2^>nul') do set "TOMCAT_VERSION=%%A"
    REM Use PowerShell for reliable XML parsing
    for /f "delims=" %%A in ('powershell -NoProfile -Command "try { ([xml](Get-Content '%NWE_CONFIG%')).SelectSingleNode('//web-servers/tomcat/version').InnerText } catch { '11.0.2' }" 2^>nul') do set "TOMCAT_VERSION=%%A"
    for /f "delims=" %%A in ('powershell -NoProfile -Command "try { ([xml](Get-Content '%NWE_CONFIG%')).SelectSingleNode('//web-servers/tomcat/install-dir').InnerText } catch { '' }" 2^>nul') do set "TOMCAT_XML_DIR=%%A"
    if defined TOMCAT_XML_DIR (
        REM Convert Unix path to Windows path
        set "TOMCAT_HOME=!TOMCAT_XML_DIR:/=\!"
        REM If it starts with \opt, prepend C:
        if "!TOMCAT_HOME:~0,4!"=="\opt" set "TOMCAT_HOME=C:!TOMCAT_HOME!"
    )
)

if defined CATALINA_HOME set "TOMCAT_HOME=%CATALINA_HOME%"

echo [*] Tomcat config: version=%TOMCAT_VERSION% dir=%TOMCAT_HOME%

REM ── 4. Install Tomcat if not present ────────────────────────────────────────
if not exist "%TOMCAT_HOME%\bin\catalina.bat" (
    echo [*] Installing Tomcat %TOMCAT_VERSION%...
    set "TOMCAT_URL=https://archive.apache.org/dist/tomcat/tomcat-11/v%TOMCAT_VERSION%/bin/apache-tomcat-%TOMCAT_VERSION%-windows-x64.zip"
    set "TOMCAT_ZIP=%TEMP%\apache-tomcat-%TOMCAT_VERSION%.zip"

    echo [*] Downloading from !TOMCAT_URL!...
    powershell -NoProfile -Command "Invoke-WebRequest -Uri '!TOMCAT_URL!' -OutFile '!TOMCAT_ZIP!' -UseBasicParsing" 2>nul
    if not exist "!TOMCAT_ZIP!" (
        REM Try the .tar.gz URL via curl
        curl -# -fL "https://archive.apache.org/dist/tomcat/tomcat-11/v%TOMCAT_VERSION%/bin/apache-tomcat-%TOMCAT_VERSION%.zip" -o "!TOMCAT_ZIP!" 2>nul
    )
    if not exist "!TOMCAT_ZIP!" (
        echo [FAIL] Could not download Tomcat. Download manually:
        echo        https://tomcat.apache.org/download-11.cgi
        echo        Extract to %TOMCAT_HOME%
        pause
        exit /b 1
    )

    echo [*] Extracting to %TOMCAT_HOME%...
    if not exist "%TOMCAT_HOME%" mkdir "%TOMCAT_HOME%"
    powershell -NoProfile -Command "Expand-Archive -Path '!TOMCAT_ZIP!' -DestinationPath '%TOMCAT_HOME%\..' -Force" 2>nul
    REM Handle nested directory from zip
    if exist "%TOMCAT_HOME%\..\apache-tomcat-%TOMCAT_VERSION%\bin\catalina.bat" (
        if not exist "%TOMCAT_HOME%\bin" (
            xcopy /E /I /Y "%TOMCAT_HOME%\..\apache-tomcat-%TOMCAT_VERSION%\*" "%TOMCAT_HOME%\" >nul
            rmdir /S /Q "%TOMCAT_HOME%\..\apache-tomcat-%TOMCAT_VERSION%" 2>nul
        )
    )
    del /Q "!TOMCAT_ZIP!" 2>nul
    echo [OK] Tomcat %TOMCAT_VERSION% installed to %TOMCAT_HOME%
) else (
    echo [OK] Tomcat already installed: %TOMCAT_HOME%
)

REM ── 5. Stamp Installer Tech ID ─────────────────────────────────────────────
set "INSTALLER_TECH_ID=%NWE_INSTALLER_TECH_ID%"
if not defined INSTALLER_TECH_ID (
    for /f "delims=" %%H in ('hostname') do set "HOST_NAME=%%H"
    for /f "delims=" %%D in ('powershell -NoProfile -Command "Get-Date -Format 'yyyyMMdd-HHmmss'"') do set "DATESTAMP=%%D"
    set "INSTALLER_TECH_ID=!HOST_NAME!-!DATESTAMP!"
)
echo [*] Installer Tech ID: %INSTALLER_TECH_ID%

if exist "%NWE_CONFIG%" (
    powershell -NoProfile -Command "$xml = [xml](Get-Content '%NWE_CONFIG%'); $tomcat = $xml.SelectSingleNode('//web-servers/tomcat/tech-id'); if($tomcat) { $tomcat.InnerText = '%INSTALLER_TECH_ID%' }; $apache = $xml.SelectSingleNode('//web-servers/apache/tech-id'); if($apache) { $apache.InnerText = '%INSTALLER_TECH_ID%' }; $xml.Save('%NWE_CONFIG%')" 2>nul
    echo [OK] Tech ID stamped in nwe-config.xml
)

REM ── 6. Sync web-deploy-config.xml ──────────────────────────────────────────
set "DEPLOY_CONFIG=%PROJECT_ROOT%\scripts\web\web-deploy-config.xml"
if exist "%DEPLOY_CONFIG%" (
    set "TOMCAT_HOME_UNIX=%TOMCAT_HOME:\=/%"
    powershell -NoProfile -Command "$xml = [xml](Get-Content '%DEPLOY_CONFIG%'); $node = $xml.SelectSingleNode('//tomcat-home'); if($node) { $node.InnerText = '%TOMCAT_HOME_UNIX%' }; $xml.Save('%DEPLOY_CONFIG%')" 2>nul
    echo [OK] web-deploy-config.xml synced
)

REM ── 7. Configure MySQL ─────────────────────────────────────────────────────
echo [*] Configuring MySQL...
net start MySQL80 2>nul
net start MySQL 2>nul
mysql -u root -e "SELECT 1;" 2>nul >nul
if errorlevel 1 (
    echo [WARN] MySQL may need manual password configuration.
    echo        Run: mysql -u root -p -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH caching_sha2_password BY 'YOUR_PASSWORD';"
) else (
    echo [OK] MySQL is running
)

REM ── 8. Setup databases ─────────────────────────────────────────────────────
echo [*] Setting up module databases...
where bash >nul 2>&1 && (
    bash "%PROJECT_ROOT%/scripts/web/setup-all-databases.sh" 2>nul
    echo [OK] Databases configured
) || (
    echo [WARN] Git Bash not found — run setup-all-databases.sh manually
)

REM ── 9. Deploy all modules ──────────────────────────────────────────────────
echo.
call "%SCRIPT_DIR%deploy-all.bat"

REM ── 10. Open firewall ports ─────────────────────────────────────────────────
echo.
echo [*] Opening firewall ports...
for %%P in (2000,5000,5512,6682,7743,7744,8080,9999,10085,20000,49111,49144,49152,49155,49166,49177,49188,49199,49200,49201,49202,49203,49204,49210,49211,49212,49213,49214) do (
    netsh advfirewall firewall add rule name="NWE-%%P" dir=in action=allow protocol=TCP localport=%%P >nul 2>&1
)
echo [OK] Firewall ports opened

REM ── 11. Register Tomcat as service ──────────────────────────────────────────
if exist "%TOMCAT_HOME%\bin\service.bat" (
    echo [*] Registering Tomcat as Windows service...
    call "%TOMCAT_HOME%\bin\service.bat" install Tomcat11 2>nul
    sc config Tomcat11 start= auto 2>nul
    net start Tomcat11 2>nul
    echo [OK] Tomcat11 service registered (auto-start)
) else (
    echo [*] Starting Tomcat...
    call "%TOMCAT_HOME%\bin\startup.bat" 2>nul
    schtasks /create /tn "NWE-Tomcat" /tr "\"%TOMCAT_HOME%\bin\startup.bat\"" /sc onstart /ru SYSTEM /f 2>nul
    echo [OK] Tomcat started, scheduled for reboot
)

echo.
echo ═══════════════════════════════════════════════════════════════
echo  Post-clone setup complete.
echo  Tomcat: %TOMCAT_HOME%
echo  All modules: http://localhost:8080/
echo ═══════════════════════════════════════════════════════════════
endlocal
