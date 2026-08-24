@echo off
REM NitroWebExpress — Build Fat JAR (Windows)
REM Location-independent: safe to invoke from any working directory.
setlocal EnableExtensions EnableDelayedExpansion

set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%..") do set "ROOT=%%~fI"

set "SRC=%ROOT%\source"
set "OUT=%ROOT%\out"
set "JAR_OUT=%ROOT%\nwe.jar"
set "MYSQL_JAR=%ROOT%\jars\mysql\mysql-connector-j-9.7.0.jar"
set "LANTERNA_JAR=%ROOT%\jars\lanterna-3.1.5.jar"
set "DJL_DIR=%ROOT%\jars\djl"
set "JPCAP_DIR=%ROOT%\jars\jpcap"
set "STAGING=%TEMP%\nwe-jar-staging-%RANDOM%"
set "SOURCE_LIST=%TEMP%\nwe-sources-%RANDOM%.txt"

if not exist "%SRC%" (
  echo [FAIL] Source directory missing: %SRC%
  exit /b 1
)
if not exist "%MYSQL_JAR%" (
  echo [FAIL] Missing dependency: %MYSQL_JAR%
  exit /b 1
)
if not exist "%LANTERNA_JAR%" (
  echo [FAIL] Missing dependency: %LANTERNA_JAR%
  exit /b 1
)
where javac >nul 2>&1 || (echo [FAIL] javac not found. Install/use Java 21.& exit /b 1)
where jar >nul 2>&1 || (echo [FAIL] jar not found. Install/use Java 21.& exit /b 1)
where powershell >nul 2>&1 || (echo [FAIL] PowerShell is required for dependency extraction.& exit /b 1)

set "CP=%OUT%;%MYSQL_JAR%;%LANTERNA_JAR%"
if exist "%DJL_DIR%" for /r "%DJL_DIR%" %%J in (*.jar) do set "CP=!CP!;%%J"
if exist "%JPCAP_DIR%" for /r "%JPCAP_DIR%" %%J in (*.jar) do set "CP=!CP!;%%J"

set "TMP_ROOT=%TEMP%"
echo === NitroWebExpress — JAR Builder (Windows) ===
echo ROOT: %ROOT%
echo.

if not exist "%OUT%" mkdir "%OUT%"

echo [1/3] Compiling sources...
dir /s /b "%SRC%\*.java" > "%SOURCE_LIST%" 2>nul
if not exist "%SOURCE_LIST%" (
  echo [FAIL] No Java sources found under %SRC%
  exit /b 1
)
for %%A in ("%SOURCE_LIST%") do if %%~zA==0 (
  echo [FAIL] No Java sources found under %SRC%
  del "%SOURCE_LIST%" 2>nul
  exit /b 1
)
javac --release 21 -cp "%CP%" -sourcepath "%SRC%" -d "%OUT%" @"%SOURCE_LIST%"
if errorlevel 1 (
  echo [FAIL] Java compilation failed.
  del "%SOURCE_LIST%" 2>nul
  exit /b 1
)
del "%SOURCE_LIST%" 2>nul
echo       Compiled.

echo [2/3] Assembling fat JAR...
if exist "%STAGING%" rmdir /S /Q "%STAGING%"
mkdir "%STAGING%"
if errorlevel 1 exit /b 1
xcopy /E /I /Y "%OUT%\*" "%STAGING%\" >nul
if errorlevel 1 exit /b 1

call :extract "%MYSQL_JAR%"
if errorlevel 1 exit /b 1
call :extract "%LANTERNA_JAR%"
if errorlevel 1 exit /b 1

if exist "%DJL_DIR%" for /r "%DJL_DIR%" %%J in (*.jar) do (
  echo %%~nxJ | findstr /i "native" >nul
  if errorlevel 1 (
    call :extract "%%J"
    if errorlevel 1 exit /b 1
  )
)
if exist "%JPCAP_DIR%" for /r "%JPCAP_DIR%" %%J in (*.jar) do (
  call :extract "%%J"
  if errorlevel 1 exit /b 1
)

if not exist "%STAGING%\META-INF" mkdir "%STAGING%\META-INF"
(
  echo Manifest-Version: 1.0
  echo Main-Class: Main
  echo Class-Path: jars/djl/pytorch-native-cpu-2.5.1-linux-x86_64.jar
) > "%STAGING%\META-INF\MANIFEST.MF"

echo [3/3] Creating %JAR_OUT%...
jar cfm "%JAR_OUT%" "%STAGING%\META-INF\MANIFEST.MF" -C "%STAGING%" .
if errorlevel 1 (
  echo [FAIL] JAR creation failed.
  rmdir /S /Q "%STAGING%" 2>nul
  exit /b 1
)

rmdir /S /Q "%STAGING%" 2>nul
for %%F in ("%JAR_OUT%") do echo       Done. Size: %%~zF bytes
echo === Run with: java -jar nwe.jar ===
exit /b 0

:extract
if not exist "%~1" exit /b 0
powershell -NoProfile -Command "$ErrorActionPreference='Stop'; Expand-Archive -LiteralPath '%~1' -DestinationPath '%STAGING%' -Force" >nul
if errorlevel 1 exit /b 1
del "%STAGING%\META-INF\MANIFEST.MF" 2>nul
del "%STAGING%\META-INF\*.SF" 2>nul
del "%STAGING%\META-INF\*.RSA" 2>nul
del "%STAGING%\META-INF\*.DSA" 2>nul
exit /b 0
