@echo off
REM UNC Chapel Hill™ — Test Local (Windows)
echo [*] Testing UNC Chapel Hill module...
echo.
echo   Backend (port 49218):
powershell -Command "try { $c = New-Object Net.Sockets.TcpClient('localhost',49218); Write-Host '  UP'; $c.Close() } catch { Write-Host '  DOWN' }"
echo   Frontend (HTTP):
powershell -Command "try { $r = Invoke-WebRequest -Uri 'http://localhost:8080/california-unc/' -UseBasicParsing -TimeoutSec 5; Write-Host ('  HTTP ' + $r.StatusCode) } catch { Write-Host '  FAIL' }"
echo.
echo [OK] Test complete.
