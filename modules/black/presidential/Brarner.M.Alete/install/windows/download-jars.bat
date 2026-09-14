@echo off
REM Brarner.M.Alete™ — Download JARs (Windows)
REM Usage: install\windows\download-jars.bat
setlocal

set SCRIPT_DIR=%~dp0
set BMA_ROOT=%SCRIPT_DIR%..\..
set LIB_DIR=%BMA_ROOT%\lib
set JARS_DIR=%BMA_ROOT%\jars
set MAVEN=https://repo1.maven.org/maven2

echo ═══════════════════════════════════════════════════════════════
echo  Brarner.M.Alete™ — JAR Downloader
echo ═══════════════════════════════════════════════════════════════

mkdir "%LIB_DIR%" 2>nul
mkdir "%JARS_DIR%" 2>nul

echo [1/9] Jakarta Servlet API 6.1.0
if not exist "%JARS_DIR%\jakarta.servlet-api-6.1.0.jar" curl -sLo "%JARS_DIR%\jakarta.servlet-api-6.1.0.jar" "%MAVEN%/jakarta/servlet/jakarta.servlet-api/6.1.0/jakarta.servlet-api-6.1.0.jar"

echo [2/9] Jakarta Annotation API 3.0.0
if not exist "%JARS_DIR%\jakarta.annotation-api-3.0.0.jar" curl -sLo "%JARS_DIR%\jakarta.annotation-api-3.0.0.jar" "%MAVEN%/jakarta/annotation/jakarta.annotation-api/3.0.0/jakarta.annotation-api-3.0.0.jar"

echo [3/9] Jakarta Servlet JSP API 4.0.0
if not exist "%JARS_DIR%\jakarta.servlet.jsp-api-4.0.0.jar" curl -sLo "%JARS_DIR%\jakarta.servlet.jsp-api-4.0.0.jar" "%MAVEN%/jakarta/servlet/jsp/jakarta.servlet.jsp-api/4.0.0/jakarta.servlet.jsp-api-4.0.0.jar"

echo [4/9] Jakarta EL API 6.0.1
if not exist "%JARS_DIR%\jakarta.el-api-6.0.1.jar" curl -sLo "%JARS_DIR%\jakarta.el-api-6.0.1.jar" "%MAVEN%/jakarta/el/jakarta.el-api/6.0.1/jakarta.el-api-6.0.1.jar"

echo [5/9] MySQL Connector/J 8.3.0
if not exist "%JARS_DIR%\mysql-connector-j-8.3.0.jar" curl -sLo "%JARS_DIR%\mysql-connector-j-8.3.0.jar" "%MAVEN%/com/mysql/mysql-connector-j/8.3.0/mysql-connector-j-8.3.0.jar"

echo [6/9] Tomcat Embed Core 11.0.2
if not exist "%JARS_DIR%\tomcat-embed-core-11.0.2.jar" curl -sLo "%JARS_DIR%\tomcat-embed-core-11.0.2.jar" "%MAVEN%/org/apache/tomcat/embed/tomcat-embed-core/11.0.2/tomcat-embed-core-11.0.2.jar"

echo [7/9] Tomcat Embed Jasper 11.0.2
if not exist "%JARS_DIR%\tomcat-embed-jasper-11.0.2.jar" curl -sLo "%JARS_DIR%\tomcat-embed-jasper-11.0.2.jar" "%MAVEN%/org/apache/tomcat/embed/tomcat-embed-jasper/11.0.2/tomcat-embed-jasper-11.0.2.jar"

echo [8/9] Tomcat Embed EL 11.0.2
if not exist "%JARS_DIR%\tomcat-embed-el-11.0.2.jar" curl -sLo "%JARS_DIR%\tomcat-embed-el-11.0.2.jar" "%MAVEN%/org/apache/tomcat/embed/tomcat-embed-el/11.0.2/tomcat-embed-el-11.0.2.jar"

echo [9/9] ECJ 3.37.0
if not exist "%JARS_DIR%\ecj-3.37.0.jar" curl -sLo "%JARS_DIR%\ecj-3.37.0.jar" "%MAVEN%/org/eclipse/jdt/ecj/3.37.0/ecj-3.37.0.jar"

echo.
echo [OK] All JARs downloaded to: %JARS_DIR%
dir /b "%JARS_DIR%\*.jar"
echo ═══════════════════════════════════════════════════════════════
endlocal
