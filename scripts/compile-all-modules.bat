@echo off
REM ═══════════════════════════════════════════════════════════════════════════════
REM NitroWebExpress™ — Compile All Modules (Windows)
REM Compiles .java → .class into out\. Safe to run after every git pull.
REM Usage: scripts\compile-all-modules.bat
REM ═══════════════════════════════════════════════════════════════════════════════
setlocal enabledelayedexpansion

set "ROOT=%~dp0.."
pushd "%ROOT%"
set "ROOT=%CD%"
popd
set "OUT=%ROOT%\out"
if not exist "%OUT%" mkdir "%OUT%"

REM ── Build classpath ─────────────────────────────────────────────────────────
set "MYSQL_JAR=%ROOT%\jars\mysql\mysql-connector-j-9.7.0.jar"
set "LANTERNA_JAR=%ROOT%\jars\lanterna-3.1.5.jar"
set "CP=%OUT%;%MYSQL_JAR%;%LANTERNA_JAR%"

REM Add DJL JARs
for /r "%ROOT%\jars\djl" %%J in (*.jar) do set "CP=!CP!;%%J"

REM Add Jpcap JARs (network packet capture)
for /r "%ROOT%\jars\jpcap" %%J in (*.jar) do set "CP=!CP!;%%J"

echo ═══════════════════════════════════════════════════════════════
echo  NWE — Compile All Modules (Windows)
echo ═══════════════════════════════════════════════════════════════
echo.

REM ── Source paths ────────────────────────────────────────────────────────────
set "SP=%ROOT%\source;%ROOT%\modules\fbi\source;%ROOT%\modules\cia\source;%ROOT%\modules\nsa\source;%ROOT%\modules\duke\source;%ROOT%\modules\library\source;%ROOT%\modules\gray\source;%ROOT%\modules\gray.a85\source;%ROOT%\modules\red\Futures\source"

REM ── 1. Core sources ─────────────────────────────────────────────────────────
echo [1/8] Core sources (source\)...
dir /s /b "%ROOT%\source\*.java" > "%TEMP%\nwe-core.txt" 2>nul
javac -d "%OUT%" -cp "%CP%" -sourcepath "%SP%" @"%TEMP%\nwe-core.txt" 2>&1 | findstr /i "error" || echo   OK
del "%TEMP%\nwe-core.txt" 2>nul

REM ── 2. FBI/CIA/NSA, Duke, Library ───────────────────────────────────────────
echo [2/8] FBI/CIA/NSA, Duke, Library...
set "MOD_FILES="
if exist "%ROOT%\modules\fbi\source\CaliforniaFBIServer.java" set "MOD_FILES=!MOD_FILES! "%ROOT%\modules\fbi\source\CaliforniaFBIServer.java""
if exist "%ROOT%\modules\cia\source\CaliforniaCIAServer.java" set "MOD_FILES=!MOD_FILES! "%ROOT%\modules\cia\source\CaliforniaCIAServer.java""
if exist "%ROOT%\modules\nsa\source\CaliforniaNSAServer.java" set "MOD_FILES=!MOD_FILES! "%ROOT%\modules\nsa\source\CaliforniaNSAServer.java""
if exist "%ROOT%\modules\duke\source\DukeUniversityServer.java" set "MOD_FILES=!MOD_FILES! "%ROOT%\modules\duke\source\DukeUniversityServer.java""
if exist "%ROOT%\modules\library\source\StanfordLibraryServer.java" set "MOD_FILES=!MOD_FILES! "%ROOT%\modules\library\source\StanfordLibraryServer.java""
if defined MOD_FILES (
    javac -d "%OUT%" -cp "%CP%" -sourcepath "%SP%" !MOD_FILES! 2>&1 | findstr /i "error" || echo   OK
) else echo   SKIP

REM ── 3. Gray registries ──────────────────────────────────────────────────────
echo [3/8] Gray Port Registry + Gray85...
set "GRAY_FILES="
if exist "%ROOT%\modules\gray\source\GrayPortRegistryServer.java" set "GRAY_FILES=!GRAY_FILES! "%ROOT%\modules\gray\source\GrayPortRegistryServer.java""
if exist "%ROOT%\modules\gray\source\PortBindingGate.java" set "GRAY_FILES=!GRAY_FILES! "%ROOT%\modules\gray\source\PortBindingGate.java""
if exist "%ROOT%\modules\gray.a85\source\Gray85PortRegistryServer.java" set "GRAY_FILES=!GRAY_FILES! "%ROOT%\modules\gray.a85\source\Gray85PortRegistryServer.java""
if exist "%ROOT%\modules\gray.a85\source\PortBindingGate85.java" set "GRAY_FILES=!GRAY_FILES! "%ROOT%\modules\gray.a85\source\PortBindingGate85.java""
if defined GRAY_FILES (
    javac -d "%OUT%" -cp "%CP%" -sourcepath "%SP%;%ROOT%\modules\gray\source;%ROOT%\modules\gray.a85\source" !GRAY_FILES! 2>&1 | findstr /i "error" || echo   OK
) else echo   SKIP

REM ── 4. Futures ──────────────────────────────────────────────────────────────
echo [4/8] Futures (DemocraticAIServer)...
if exist "%ROOT%\modules\red\Futures\source" (
    dir /s /b "%ROOT%\modules\red\Futures\source\*.java" > "%TEMP%\futures.txt" 2>nul
    for %%F in ("%TEMP%\futures.txt") do if %%~zF gtr 0 (
        javac -d "%OUT%" -cp "%CP%" -sourcepath "%SP%" @"%TEMP%\futures.txt" 2>&1 | findstr /i "error" || echo   OK
    ) else echo   SKIP
    del "%TEMP%\futures.txt" 2>nul
) else echo   SKIP

REM ── 5. StrernaryDirectory ───────────────────────────────────────────────────
echo [5/8] StrernaryDirectory (port 2000)...
if exist "%ROOT%\source\strernary\StrernaryDirectoryServer.java" (
    javac -d "%OUT%" -cp "%CP%" -sourcepath "%ROOT%\source" "%ROOT%\source\strernary\StrernaryDirectoryServer.java" 2>&1 | findstr /i "error" || echo   OK
) else echo   SKIP

REM ── 6. AE6E66 ──────────────────────────────────────────────────────────────
echo [6/8] AE6E66 (UK Parliament)...
if exist "%ROOT%\modules\AE6E66\source" (
    dir /s /b "%ROOT%\modules\AE6E66\source\*.java" > "%TEMP%\ae6e66.txt" 2>nul
    for %%F in ("%TEMP%\ae6e66.txt") do if %%~zF gtr 0 (
        javac -d "%OUT%" -cp "%CP%" -sourcepath "%SP%;%ROOT%\modules\AE6E66\source" @"%TEMP%\ae6e66.txt" 2>&1 | findstr /i "error" || echo   OK
    ) else echo   SKIP
    del "%TEMP%\ae6e66.txt" 2>nul
) else echo   SKIP

REM ── 7. GDGH ─────────────────────────────────────────────────────────────────
echo [7/8] Green.Durham.Grass.and.Herb...
if exist "%ROOT%\modules\Green.Durham.Grass.and.Herb\source" (
    dir /s /b "%ROOT%\modules\Green.Durham.Grass.and.Herb\source\*.java" > "%TEMP%\gdgh.txt" 2>nul
    for %%F in ("%TEMP%\gdgh.txt") do if %%~zF gtr 0 (
        javac -d "%OUT%" -cp "%CP%" -sourcepath "%SP%;%ROOT%\modules\Green.Durham.Grass.and.Herb\source" @"%TEMP%\gdgh.txt" 2>&1 | findstr /i "error" || echo   OK
    ) else echo   SKIP
    del "%TEMP%\gdgh.txt" 2>nul
) else echo   SKIP

REM ── 8. Verify ───────────────────────────────────────────────────────────────
echo [8/8] Verifying key classes...
set MISSING=0
if not exist "%OUT%\Main.class" (echo   [MISSING] Main.class & set /a MISSING+=1)
if not exist "%OUT%\source\CaliforniaFBIServer.class" (echo   [MISSING] CaliforniaFBIServer.class & set /a MISSING+=1)
if not exist "%OUT%\source\CaliforniaCIAServer.class" (echo   [MISSING] CaliforniaCIAServer.class & set /a MISSING+=1)
if not exist "%OUT%\source\CaliforniaNSAServer.class" (echo   [MISSING] CaliforniaNSAServer.class & set /a MISSING+=1)
if not exist "%OUT%\strernary\StrernaryDirectoryServer.class" (echo   [MISSING] StrernaryDirectoryServer.class & set /a MISSING+=1)
if %MISSING%==0 echo   All key classes present.

echo.
echo ═══════════════════════════════════════════════════════════════
echo  Compilation complete.
echo  Restart: scripts\start-backends.bat
echo ═══════════════════════════════════════════════════════════════
endlocal
