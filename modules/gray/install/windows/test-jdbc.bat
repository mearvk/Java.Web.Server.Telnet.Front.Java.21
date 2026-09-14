@echo off
REM Gray — JDBC Connectivity Test (Windows)
REM Usage: install\windows\test-jdbc.bat
setlocal

set SCRIPT_DIR=%~dp0
set MOD_ROOT=%SCRIPT_DIR%..\..set NWE_ROOT=%SCRIPT_DIR%..\..\..\..\..
set DB_PROPS=%MOD_ROOT%\servlets\servlet\src\main\webapp\WEB-INF\db.properties
set JDBC_JAR=
set TMP_DIR=%TEMP%\gray-registry-jdbc-test

echo ═══════════════════════════════════════════════════════════════
echo  Gray — JDBC Connectivity Test (Windows)
echo ═══════════════════════════════════════════════════════════════

if not exist "%DB_PROPS%" (
    echo [FAIL] db.properties not found: %DB_PROPS%
    pause & exit /b 1
)

for %%f in ("%NWE_ROOT%\modules\black\presidential\Brarner.M.Alete\jars\mysql-connector-j-*.jar") do set JDBC_JAR=%%f
if "%JDBC_JAR%"=="" for %%f in ("%NWE_ROOT%\jars\mysql\mysql-connector-j-*.jar") do set JDBC_JAR=%%f
if "%JDBC_JAR%"=="" (
    echo [FAIL] mysql-connector-j-*.jar not found
    pause & exit /b 1
)
echo [OK] JAR: %JDBC_JAR%

if not exist "%TMP_DIR%" mkdir "%TMP_DIR%"

(
echo import java.sql.*;
echo import java.util.Properties;
echo import java.io.*;
echo public class TestJdbc {
echo     public static void main(String[] args^) throws Exception {
echo         Properties p = new Properties(^);
echo         p.load(new FileInputStream(args[0]^)^);
echo         Class.forName("com.mysql.cj.jdbc.Driver"^);
echo         System.out.println("[*] Connecting: " + p.getProperty("db.url"^)^);
echo         Connection c = DriverManager.getConnection(p.getProperty("db.url"^),p.getProperty("db.user"^),p.getProperty("db.password",""^)^);
echo         System.out.println("[OK] " + c.getMetaData(^).getDatabaseProductName(^) + " " + c.getMetaData(^).getDatabaseProductVersion(^)^);
echo         c.close(^);
echo         System.out.println("=== JDBC TEST PASSED ==="^);
echo     }
echo }
) > "%TMP_DIR%\TestJdbc.java"

javac -cp "%JDBC_JAR%" "%TMP_DIR%\TestJdbc.java" -d "%TMP_DIR%"
java -cp "%TMP_DIR%;%JDBC_JAR%" TestJdbc "%DB_PROPS%"
rmdir /s /q "%TMP_DIR%" 2>nul
pause
endlocal
