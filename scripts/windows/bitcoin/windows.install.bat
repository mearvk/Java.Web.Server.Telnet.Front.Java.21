@echo off
setlocal
set "BITCOIN_DIR=C:\Bitcoin\daemon"
set "DATA_DIR=%APPDATA%\Bitcoin"
set "RPC_PORT=2222"

:: Create data directory if it doesn't exist.
if not exist "%DATA_DIR%" mkdir "%DATA_DIR%"

:: Create a local regtest configuration using Bitcoin Core cookie authentication.
:: No rpcuser/rpcpassword credentials are generated or stored by this script.
if not exist "%DATA_DIR%\bitcoin.conf" (
    echo server=1 > "%DATA_DIR%\bitcoin.conf"
    echo regtest=1 >> "%DATA_DIR%\bitcoin.conf"
    echo txindex=1 >> "%DATA_DIR%\bitcoin.conf"
    echo rpcbind=127.0.0.1 >> "%DATA_DIR%\bitcoin.conf"
    echo rpcport=%RPC_PORT% >> "%DATA_DIR%\bitcoin.conf"
    echo [Done] Created hardened local bitcoin.conf in %DATA_DIR%
)

:: Start bitcoind.
echo Starting Bitcoin Daemon...
start "" "%BITCOIN_DIR%\bitcoind.exe" -daemon -regtest -rpcport=%RPC_PORT%

:: Verify it's running through the local RPC endpoint.
timeout /t 5 >nul
"%BITCOIN_DIR%\bitcoin-cli.exe" -regtest -rpcport=%RPC_PORT% getblockchaininfo
if errorlevel 1 (
    echo [ERROR] Bitcoin Core health check failed.
    exit /b 1
)

echo [OK] Bitcoin Core is responding on regtest RPC port %RPC_PORT%.
endlocal
