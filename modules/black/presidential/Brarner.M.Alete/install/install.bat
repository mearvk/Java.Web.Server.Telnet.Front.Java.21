@echo off
echo ============================================
echo  MEARVK Project - Central Install Script
echo ============================================
echo.

set PROJECT_ROOT=%~dp0..

echo [1/4] Installing JARs...
call "%~dp0install_jars.bat"
echo.

echo [2/4] Setting classpath...
call "%~dp0..\configuration\install_classpath.bat"
echo.

echo [3/4] Installing MySQL...
call "%~dp0install_mysql.bat"
echo.

echo [4/4] Checking ports...
call "%~dp0..\configuration\check_ports.bat"
echo.

echo ============================================
echo  Install complete.
echo ============================================
