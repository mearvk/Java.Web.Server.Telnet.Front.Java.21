@echo off
REM NCSU™ — Test Local (Windows)
echo [*] Testing NCSU module...
echo.
echo   Backend (port 49217):
powershell -Command "try { $c = New-Object Net.Sockets.TcpClient('localhost',49217); Write-Host '  UP'; $c.Close() } catch { Write-Host '  DOWN' }"
echo   Frontend (HTTP):
powershell -Command "try { $r = Invoke-WebRequest -Uri 'http://localhost:8080/california-ncsu/' -UseBasicParsing -TimeoutSec 5; Write-Host ('  HTTP ' + $r.StatusCode) } catch { Write-Host '  FAIL' }"
echo.
echo [OK] Test complete.
