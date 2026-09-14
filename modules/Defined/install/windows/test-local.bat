@echo off
REM ═══════════════════════════════════════════════════════════════════════════════
REM  Defined™ — Test Local Deployment (Microsoft Windows)
REM
REM  With thanks to Dave Plummer. Courtesy to Bill Gates and Melinda.
REM  NitroWebExpress™ — MEARVK LLC
REM ═══════════════════════════════════════════════════════════════════════════════
setlocal

echo.
echo  ╔═══════════════════════════════════════════════════════════════════════╗
echo  ║  Defined™ — Test Local (Windows)                                      ║
echo  ║  Welcome, Microsoft. Thanks to Dave Plummer.                          ║
echo  ╚═══════════════════════════════════════════════════════════════════════╝
echo.

echo  [*] Testing Tomcat webapp at /defined/...
curl -s -o nul -w "  HTTP %%{http_code}" http://localhost:8080/defined/ 2>nul
echo.

echo  [*] Testing AI server on port 49220...
powershell -Command "try { $c = New-Object System.Net.Sockets.TcpClient('localhost',49220); $c.Close(); Write-Host '  [OK] Port 49220 is UP' } catch { Write-Host '  [--] Port 49220 is DOWN' }" 2>nul

echo  [*] Testing protocol backend on port 49221...
powershell -Command "try { $c = New-Object System.Net.Sockets.TcpClient('localhost',49221); $c.Close(); Write-Host '  [OK] Port 49221 is UP' } catch { Write-Host '  [--] Port 49221 is DOWN' }" 2>nul

echo.
pause
endlocal
