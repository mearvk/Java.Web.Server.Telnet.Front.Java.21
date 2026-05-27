@echo off
TITLE FTP and SFTP Server Installer for Windows 11
echo ========================================================
echo Installing FTP and SFTP features on Windows 11...
echo ========================================================

:: 1. Install Native FTP Server (via IIS)
echo.
echo Installing FTP Server...
dism /online /enable-feature /featurename:IIS-WebServerRole /quiet /norestart
dism /online /enable-feature /featurename:IIS-ManagementConsole /quiet /norestart
dism /online /enable-feature /featurename:IIS-FTPServer /quiet /norestart
dism /online /enable-feature /featurename:IIS-FTPSvc /quiet /norestart
echo FTP Server installed.

:: 2. Install SFTP Server (OpenSSH)
echo.
echo Installing OpenSSH Server for SFTP...
dism /online /Add-Capability /CapabilityName:OpenSSH.Server~~~~0.0.1.0 /quiet

:: 3. Configure and start SFTP/SSH services
echo.
echo Starting SSH services...
sc config sshd start= auto
net start sshd

:: 4. Open Firewall Ports
echo.
echo Opening Firewall Ports for FTP and SFTP...
netsh advfirewall firewall add rule name="FTP Server (Port 21)" dir=in action=allow protocol=TCP localport=21
netsh advfirewall firewall add rule name="SFTP (Port 22)" dir=in action=allow protocol=TCP localport=22
netsh advfirewall firewall add rule name="FTP Passive Mode" dir=in action=allow protocol=TCP localport=1024-65535

echo ========================================================
echo Installation complete!
echo Note: For FTP, you must configure sites in IIS Manager.
echo For SFTP, you can now connect via any SFTP client.
echo ========================================================
pause
