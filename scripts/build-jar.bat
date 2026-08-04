@echo off
REM ═══════════════════════════════════════════════════════════════════════════════
REM NitroWebExpress™ — Build Fat JAR (Windows)
REM Compiles all sources and packages into nwe.jar.
REM Usage: scripts\build-jar.bat
REM ═══════════════════════════════════════════════════════════════════════════════
setlocal enabledelayedexpansion

set "ROOT=%~dp0.."
pushd "%ROOT%"
set "ROOT=%CD%"
popd

set "SRC=%ROOT%\source"
set "OUT=%ROOT%\out"
set "JAR_OUT=%ROOT%\nwe.jar"
set "MYSQL_JAR=%ROOT%\jars\mysql\mysql-connector-j-9.7.0.jar"
set "LANTERNA_JAR=%ROOT%\jars\lanterna-3.1.5.jar"
set "DJL_DIR=%ROOT%\jars\djl"
set "STAGING=%TEMP%\nwe-jar-staging"

echo === NitroWebExpress — JAR Builder (Windows) ===
echo ROOT: %ROOT%
echo.

REM ── 1. Compile ──────────────────────────────────────────────────────────────
echo [1/3] Compiling sources...
if not exist "%OUT%" mkdir "%OUT%"
set "CP=%OUT%;%MYSQL_JAR%;%LANTERNA_JAR%"
for /r "%DJL_DIR%" %%J in (*.jar) do set "CP=!CP!;%%J"
for /r "%ROOT%\jars\jpcap" %%J in (*.jar) do set "CP=!CP!;%%J"

dir /s /b "%SRC%\*.java" > "%TEMP%\nwe-sources.txt" 2>nul
javac --release 21 -cp "%CP%" -sourcepath "%SRC%" -d "%OUT%" @"%TEMP%\nwe-sources.txt" 2>&1
del "%TEMP%\nwe-sources.txt" 2>nul
echo       Compiled.

REM ── 2. Assemble fat JAR ────────────────────────────────────────────────────
echo [2/3] Assembling fat JAR...
if exist "%STAGING%" rmdir /S /Q "%STAGING%"
mkdir "%STAGING%"

REM Copy application classes
xcopy /E /I /Y "%OUT%\*" "%STAGING%\" >nul 2>&1

REM Extract dependency JARs
if exist "%MYSQL_JAR%" (
    powershell -NoProfile -Command "Expand-Archive -Path '%MYSQL_JAR%' -DestinationPath '%STAGING%' -Force" 2>nul
    del "%STAGING%\META-INF\MANIFEST.MF" 2>nul
    del "%STAGING%\META-INF\*.SF" 2>nul
    del "%STAGING%\META-INF\*.RSA" 2>nul
)
if exist "%LANTERNA_JAR%" (
    powershell -NoProfile -Command "Expand-Archive -Path '%LANTERNA_JAR%' -DestinationPath '%STAGING%' -Force" 2>nul
    del "%STAGING%\META-INF\MANIFEST.MF" 2>nul
    del "%STAGING%\META-INF\*.SF" 2>nul
)

REM DJL jars (skip native blobs)
for /r "%DJL_DIR%" %%J in (*.jar) do (
    echo %%~nxJ | findstr /i "native" >nul || (
        powershell -NoProfile -Command "Expand-Archive -Path '%%J' -DestinationPath '%STAGING%' -Force" 2>nul
        del "%STAGING%\META-INF\MANIFEST.MF" 2>nul
        del "%STAGING%\META-INF\*.SF" 2>nul
    )
)

REM Write manifest
if not exist "%STAGING%\META-INF" mkdir "%STAGING%\META-INF"
(
echo Manifest-Version: 1.0
echo Main-Class: Main
echo Class-Path: jars/djl/pytorch-native-cpu-2.5.1-linux-x86_64.jar
) > "%STAGING%\META-INF\MANIFEST.MF"

REM ── 3. Create JAR ──────────────────────────────────────────────────────────
echo [3/3] Creating %JAR_OUT%...
jar cfm "%JAR_OUT%" "%STAGING%\META-INF\MANIFEST.MF" -C "%STAGING%" .

REM Cleanup staging
rmdir /S /Q "%STAGING%" 2>nul

for %%F in ("%JAR_OUT%") do echo       Done. Size: %%~zF bytes
echo.
echo === Run with: java -jar nwe.jar ===
endlocal
