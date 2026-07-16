@echo off
REM UNC Chapel Hill™ — Deploy Local (Windows)
set SCRIPT_DIR=%~dp0
set MOD_ROOT=%SCRIPT_DIR%\..\..
bash "%MOD_ROOT%\servlets\deploy-local.sh" %*
