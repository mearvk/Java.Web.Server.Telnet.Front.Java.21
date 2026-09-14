@echo off
setlocal EnableExtensions

if "%~1"=="" goto :usage
if "%~2"=="" goto :usage

set "ACTION=%~1"
set "VENDOR=%~2"
set "PACKAGE=%~3"

where winget >nul 2>&1 || (
  echo ERROR: winget is required.
  exit /b 1
)

if /I "%ACTION%"=="list" goto :list
if "%PACKAGE%"=="" goto :usage

call :resolve "%VENDOR%" "%PACKAGE%"
if errorlevel 1 exit /b 1

if /I "%ACTION%"=="install" winget install --id "%ID%" --exact --accept-package-agreements --accept-source-agreements & goto :done
if /I "%ACTION%"=="update"  winget upgrade --id "%ID%" --exact --accept-package-agreements --accept-source-agreements & goto :done
if /I "%ACTION%"=="remove"  winget uninstall --id "%ID%" --exact & goto :done
if /I "%ACTION%"=="status"  winget list --id "%ID%" --exact & goto :done

echo ERROR: Unknown action: %ACTION%
exit /b 2

:resolve
set "ID="
if /I "%~1"=="microsoft" (
  if /I "%~2"=="edge" set "ID=Microsoft.Edge"
  if /I "%~2"=="vscode" set "ID=Microsoft.VisualStudioCode"
  if /I "%~2"=="powershell" set "ID=Microsoft.PowerShell"
  if /I "%~2"=="dotnet" set "ID=Microsoft.DotNet.SDK.8"
  if /I "%~2"=="git" set "ID=Git.Git"
)
if /I "%~1"=="apple" (
  if /I "%~2"=="icloud" set "ID=Apple.iCloud"
  if /I "%~2"=="applemusic" set "ID=Apple.AppleMusic"
  if /I "%~2"=="devices" set "ID=Apple.AppleDevices"
)
if not defined ID (
  echo ERROR: Unsupported vendor/package alias.
  exit /b 1
)
exit /b 0

:list
echo Microsoft: edge, vscode, powershell, dotnet, git
echo Apple:     icloud, applemusic, devices
exit /b 0

:usage
echo Usage: US-House-Software.cmd ^<install^|update^|remove^|status^|list^> ^<microsoft^|apple^> [package]
exit /b 2

:done
exit /b %ERRORLEVEL%
