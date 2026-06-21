@echo off
REM strernary-client.bat — Interactive client for Strernary port 20000
REM Usage: strernary-client.bat [host] [national_id]
REM   Connects via telnet to the Strernary inference server.
REM   The server will prompt for NationalID. If not registered, it directs to port 49152.

set HOST=%1
if "%HOST%"=="" set HOST=localhost

set NID=%2
set PORT=20000

echo [Strernary] Connecting to %HOST%:%PORT%...
echo [Strernary] The server will ask for your NationalID.
echo [Strernary] If you don't have one, press Enter to skip or register at port 49152.
echo.

if "%NID%"=="" (
    telnet %HOST% %PORT%
) else (
    echo %NID% | telnet %HOST% %PORT%
)
