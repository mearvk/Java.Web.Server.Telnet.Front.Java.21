@echo off
REM Brarner.M.Alete™ — Test JDBC Connectivity (Windows)
REM Compiles and runs a Java class to verify db.properties credentials.
REM Usage: install\windows\test-jdbc.bat

setlocal
set SCRIPT_DIR=%~dp0
set BMA_ROOT=%SCRIPT_DIR%..\..
set DB_PROPS=%BMA_ROOT%\servlets\servlet\src\main\webapp\WEB-INF\db.properties
set LIB_DIR=%BMA_ROOT%\lib
set TMP_DIR=%TEMP%\bma-jdbc-test

echo ═══════════════════════════════════════════════════════════════
echo  Brarner.M.Alete™ — JDBC Connectivity Test (Windows)
echo ═══════════════════════════════════════════════════════════════

if not exist "%DB_PROPS%" (
    echo [FAIL] db.properties not found.
    pause
    exit /b 1
)

REM Find MySQL JAR
set MYSQL_JAR=
for %%f in ("%LIB_DIR%\mysql-connector-j-*.jar") do set MYSQL_JAR=%%f
if "%MYSQL_JAR%"=="" (
    echo [FAIL] MySQL connector JAR not found in %LIB_DIR%
    pause
    exit /b 1
)
echo [*] JAR: %MYSQL_JAR%

if not exist "%TMP_DIR%" mkdir "%TMP_DIR%"

REM Write test class
(
echo import java.sql.*;
echo import java.util.Properties;
echo import java.io.*;
echo public class TestJdbc {
echo     public static void main(String[] args^) throws Exception {
echo         Properties p = new Properties(^);
echo         p.load(new FileInputStream(args[0]^)^);
echo         Class.forName(p.getProperty("db.driver","com.mysql.cj.jdbc.Driver"^)^);
echo         System.out.println("[*] Connecting: " + p.getProperty("db.url"^)^);
echo         Connection c = DriverManager.getConnection(p.getProperty("db.url"^),p.getProperty("db.user"^),p.getProperty("db.password",""^)^);
echo         System.out.println("[OK] Connected: " + c.getMetaData(^).getDatabaseProductVersion(^)^);
echo         c.close(^);
echo         System.out.println("[OK] JDBC TEST PASSED"^);
echo     }
echo }
) > "%TMP_DIR%\TestJdbc.java"

echo [*] Compiling...
javac -cp "%MYSQL_JAR%" "%TMP_DIR%\TestJdbc.java" -d "%TMP_DIR%"

echo [*] Running...
java -cp "%TMP_DIR%;%MYSQL_JAR%" TestJdbc "%DB_PROPS%"

rmdir /s /q "%TMP_DIR%" 2>nul
pause
