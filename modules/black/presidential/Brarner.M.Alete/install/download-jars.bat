@echo off
REM Brarner.M.Alete™ — Download JARs Script (Windows)
REM Downloads all required JARs to run the BMA servlet site.
setlocal enabledelayedexpansion

set "SCRIPT_DIR=%~dp0"
set "BMA_ROOT=%SCRIPT_DIR%.."
set "LIB_DIR=%BMA_ROOT%\lib"
set "MVN=https://repo1.maven.org/maven2"

echo ═══════════════════════════════════════════════════════════════
echo  Brarner.M.Alete™ — JAR Downloader (Windows)
echo  Fetching servlet runtime dependencies...
echo ═══════════════════════════════════════════════════════════════

if not exist "%LIB_DIR%" mkdir "%LIB_DIR%"

echo.
echo [1/5] Jakarta Servlet API 6.1.0
if not exist "%LIB_DIR%\jakarta.servlet-api-6.1.0.jar" (
    powershell -Command "Invoke-WebRequest -Uri '%MVN%/jakarta/servlet/jakarta.servlet-api/6.1.0/jakarta.servlet-api-6.1.0.jar' -OutFile '%LIB_DIR%\jakarta.servlet-api-6.1.0.jar'"
    echo   [OK] Downloaded.
) else (echo   [skip] Already exists.)

echo [2/5] Jakarta Annotation API 3.0.0
if not exist "%LIB_DIR%\jakarta.annotation-api-3.0.0.jar" (
    powershell -Command "Invoke-WebRequest -Uri '%MVN%/jakarta/annotation/jakarta.annotation-api/3.0.0/jakarta.annotation-api-3.0.0.jar' -OutFile '%LIB_DIR%\jakarta.annotation-api-3.0.0.jar'"
    echo   [OK] Downloaded.
) else (echo   [skip] Already exists.)

echo [3/5] MySQL Connector/J 8.3.0
if not exist "%LIB_DIR%\mysql-connector-j-8.3.0.jar" (
    powershell -Command "Invoke-WebRequest -Uri '%MVN%/com/mysql/mysql-connector-j/8.3.0/mysql-connector-j-8.3.0.jar' -OutFile '%LIB_DIR%\mysql-connector-j-8.3.0.jar'"
    echo   [OK] Downloaded.
) else (echo   [skip] Already exists.)

echo [4/5] Apache Tomcat Embed Core 11.0.2
if not exist "%LIB_DIR%\tomcat-embed-core-11.0.2.jar" (
    powershell -Command "Invoke-WebRequest -Uri '%MVN%/org/apache/tomcat/embed/tomcat-embed-core/11.0.2/tomcat-embed-core-11.0.2.jar' -OutFile '%LIB_DIR%\tomcat-embed-core-11.0.2.jar'"
    echo   [OK] Downloaded.
) else (echo   [skip] Already exists.)

echo [5/5] Apache Tomcat Embed Jasper 11.0.2
if not exist "%LIB_DIR%\tomcat-embed-jasper-11.0.2.jar" (
    powershell -Command "Invoke-WebRequest -Uri '%MVN%/org/apache/tomcat/embed/tomcat-embed-jasper/11.0.2/tomcat-embed-jasper-11.0.2.jar' -OutFile '%LIB_DIR%\tomcat-embed-jasper-11.0.2.jar'"
    echo   [OK] Downloaded.
) else (echo   [skip] Already exists.)

echo.
echo [OK] All JARs downloaded to: %LIB_DIR%
dir /B "%LIB_DIR%\*.jar" 2>nul
echo ═══════════════════════════════════════════════════════════════
endlocal
