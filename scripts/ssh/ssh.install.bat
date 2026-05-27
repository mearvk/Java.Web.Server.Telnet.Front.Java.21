@echo off
:: Check for Administrator privileges
net session >nul 2>&1
if %errorLevel% == 0 (
    echo Installing OpenSSH Client...
    powershell -Command "Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0"
    echo.
    echo Installation complete! You can now use the 'ssh' command in Command Prompt or PowerShell.
) else (
    echo ERROR: Please run this file as Administrator.
)
pause
