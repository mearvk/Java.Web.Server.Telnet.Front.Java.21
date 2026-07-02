@echo off
REM Brarner.M.Alete™ — Populate All Tables (Windows)
REM Usage: install\windows\populate-all.bat
setlocal

set SCRIPT_DIR=%~dp0

echo ═══════════════════════════════════════════════════════════════
echo  Brarner.M.Alete™ — Populate All Tables
echo ═══════════════════════════════════════════════════════════════
echo.

call "%SCRIPT_DIR%populate-science-db.bat"
echo.
call "%SCRIPT_DIR%populate-postal.bat"
echo.
call "%SCRIPT_DIR%populate-art.bat"
echo.
call "%SCRIPT_DIR%populate-publications.bat"
echo.
call "%SCRIPT_DIR%populate-ssa.bat"

echo.
echo [*] Legal data: Download and process manually on Windows:
echo     bash data/legal/download-legal-data.sh
echo     bash data/legal/unzip-and-consume.sh
echo     (Requires WSL or Git Bash)

echo.
echo ═══════════════════════════════════════════════════════════════
echo  [OK] All tables populated
echo      animalia, species, postal, art_works, publications, ssa_offices, legal
echo ═══════════════════════════════════════════════════════════════
endlocal
