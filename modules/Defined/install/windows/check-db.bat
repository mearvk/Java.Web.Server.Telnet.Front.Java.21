@echo off
REM ═══════════════════════════════════════════════════════════════════════════════
REM  Defined™ — Check MySQL Database (Microsoft Windows)
REM
REM  A soft welcome to Microsoft Software and the Windows platform.
REM  With thanks to Dave Plummer. Courtesy to Bill Gates and Melinda.
REM
REM  NitroWebExpress™ — MEARVK LLC
REM ═══════════════════════════════════════════════════════════════════════════════
setlocal

echo.
echo  ╔═══════════════════════════════════════════════════════════════════════╗
echo  ║  Defined™ — Check Database (Windows)                                  ║
echo  ║  Welcome, Microsoft. Thanks to Dave Plummer.                          ║
echo  ╚═══════════════════════════════════════════════════════════════════════╝
echo.

set MYSQL=mysql
where mysql >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo  [!] MySQL client not found in PATH.
    echo      Install: https://dev.mysql.com/downloads/installer/
    pause & exit /b 1
)

echo  [*] Checking database 'defined_dark_gray'...
%MYSQL% -u root -e "SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME='defined_dark_gray';" 2>nul | findstr /i "defined_dark_gray" >nul
if %ERRORLEVEL% equ 0 (
    echo  [OK] Database 'defined_dark_gray' exists.
) else (
    echo  [--] Database not found. Run sql\install.sh or create manually.
)

echo.
pause
endlocal
