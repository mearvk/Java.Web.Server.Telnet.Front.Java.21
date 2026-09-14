@echo off
setlocal
set "PS=%~dp0US-House-Convenience.ps1"
if not exist "%PS%" (
  echo ERROR: %PS% not found.
  exit /b 1
)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PS%" %*
exit /b %ERRORLEVEL%
