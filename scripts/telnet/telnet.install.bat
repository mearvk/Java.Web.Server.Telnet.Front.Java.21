@echo off
echo Installing Telnet Client...
dism /online /Enable-Feature /FeatureName:TelnetClient
echo.
echo Installation complete. Press any key to exit.
pause >nul
