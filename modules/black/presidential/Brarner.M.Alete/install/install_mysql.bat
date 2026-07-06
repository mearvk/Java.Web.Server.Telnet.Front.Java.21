@echo off
echo --- MySQL Install Check ---

where mysql >nul 2>&1
if %errorlevel%==0 (
    echo MySQL client already installed.
    mysql --version
) else (
    echo MySQL not found on PATH.
    echo.
    echo Options:
    echo   1. Download MySQL Community Server:
    echo      https://dev.mysql.com/downloads/mysql/
    echo.
    echo   2. Install via winget:
    echo      winget install Oracle.MySQL
    echo.
    echo   3. Install via choco:
    echo      choco install mysql
    echo.
    echo Attempting winget install...
    winget install Oracle.MySQL --accept-package-agreements --accept-source-agreements
)

echo.
echo --- MySQL Service Status ---
sc query MySQL >nul 2>&1
if %errorlevel%==0 (
    sc query MySQL | findstr STATE
) else (
    sc query MySQL80 >nul 2>&1
    if %errorlevel%==0 (
        sc query MySQL80 | findstr STATE
    ) else (
        echo MySQL service not found. Install MySQL Server to register the service.
    )
)
