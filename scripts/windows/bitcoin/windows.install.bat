@echo off
set "BITCOIN_DIR=C:\Bitcoin\daemon"
set "DATA_DIR=%APPDATA%\Bitcoin"

:: Create data directory if it doesn't exist
if not exist "%DATA_DIR%" mkdir "%DATA_DIR%"

:: Create a basic bitcoin.conf file if it doesn't exist
if not exist "%DATA_DIR%\bitcoin.conf" (
    echo server=1 > "%DATA_DIR%\bitcoin.conf"
    echo rpcuser=your_username >> "%DATA_DIR%\bitcoin.conf"
    echo rpcpassword=your_secure_password >> "%DATA_DIR%\bitcoin.conf"
    echo txindex=1 >> "%DATA_DIR%\bitcoin.conf"
    echo [Done] Created bitcoin.conf in %DATA_DIR%
)

:: Start bitcoind
echo Starting Bitcoin Daemon...
start "" "%BITCOIN_DIR%\bitcoind.exe" -daemon

:: Verify it's running
timeout /t 5
"%BITCOIN_DIR%\bitcoin-cli.exe" getblockchaininfo
pause
