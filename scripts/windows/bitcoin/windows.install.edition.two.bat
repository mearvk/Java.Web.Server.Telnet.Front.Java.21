@echo off
setlocal EnableDelayedExpansion

:: Set your desired installation directory
set "INSTALL_DIR=C:\BitcoinNode"

:: Download and Install URL (Bitcoin Core 31.0 Windows 64-bit)
set "DOWNLOAD_URL=https://bitcoincore.org"

echo Creating installation directory...
mkdir "%INSTALL_DIR%"
cd "%INSTALL_DIR%"

echo Downloading Bitcoin Core...
powershell -Command "Invoke-WebRequest -Uri '%DOWNLOAD_URL%' -OutFile 'bitcoin-core.zip'"

echo Extracting files...
powershell -Command "Expand-Archive -Path 'bitcoin-core.zip' -DestinationPath '.' -Force"

echo Creating start_bitcoind.bat script...
cd "%INSTALL_DIR%"
(
    echo @echo off
    echo echo Starting Bitcoin Daemon...
    echo cd "%INSTALL_DIR%\bitcoin-31.0\bin"
    echo start bitcoind.exe -server
    echo echo Daemon is running.
    echo pause
) > start_bitcoind.bat

echo Creating bitcoin-cli shortcut...
(
    echo @echo off
    echo cd "%INSTALL_DIR%\bitcoin-31.0\bin"
    echo echo Executing bitcoin-cli...
    echo bitcoin-cli.exe %%*
) > bitcoin-cli.bat

echo Installation complete!
echo Run 'start_bitcoind.bat' to start the node, and use 'bitcoin-cli.bat' for commands.
pause
