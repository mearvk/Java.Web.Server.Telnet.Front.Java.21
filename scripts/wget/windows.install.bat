@echo off
echo Downloading Wget for Windows...
powershell -Command "Invoke-WebRequest -Uri 'https://eternallybored.org' -OutFile '%TEMP%\wget.exe'"

echo.
echo Moving Wget to C:\Windows\System32...
copy "%TEMP%\wget.exe" C:\Windows\System32\wget.exe

echo.
echo Cleaning up...
del "%TEMP%\wget.exe"

echo.
echo Verification:
wget --version

echo.
echo Installation complete! You can now use 'wget' from any Command Prompt window.
pause
