# AE6E66 — MySQL Setup for Windows
# PowerShell script. Run as Administrator.
# Assumes MySQL 8.x installed via MSI or Chocolatey.

#Requires -RunAsAdministrator
$ErrorActionPreference = "Stop"

$DB_NAME = "nwe_ae6e66"
$DB_USER = "ae6e66_svc"
$DB_PASS = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 24 | ForEach-Object { [char]$_ })

Write-Host "-- : [AE6E66] Setting up MySQL database: $DB_NAME" -ForegroundColor Green

# Find mysql.exe
$MysqlPath = Get-Command mysql -ErrorAction SilentlyContinue
if (-not $MysqlPath) {
    $MysqlPath = Get-ChildItem "C:\Program Files\MySQL\MySQL Server*\bin\mysql.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $MysqlPath) {
        Write-Error "MySQL not found. Install via https://dev.mysql.com/downloads/ or: choco install mysql"
        exit 1
    }
}

$SQL = @"
CREATE DATABASE IF NOT EXISTS ``$DB_NAME``
    CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';
GRANT SELECT, INSERT, UPDATE ON ``$DB_NAME``.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;

USE ``$DB_NAME``;

CREATE TABLE IF NOT EXISTS contacts (
    id INT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(254),
    phone VARCHAR(64),
    ministry VARCHAR(255),
    source ENUM('HOL','HOC','HOC-Enquiries') NOT NULL,
    career TEXT,
    crawl_date DATE NOT NULL,
    INDEX idx_source (source),
    INDEX idx_ministry (ministry)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS sent_log (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    recipient VARCHAR(254) NOT NULL,
    subject VARCHAR(255) NOT NULL,
    sha256 CHAR(64) NOT NULL,
    sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status ENUM('success','failure') NOT NULL,
    error_msg VARCHAR(512),
    INDEX idx_sent_at (sent_at),
    INDEX idx_recipient (recipient)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS crawl_history (
    id INT AUTO_INCREMENT PRIMARY KEY,
    crawl_date DATE NOT NULL,
    hol_count INT DEFAULT 0,
    hoc_count INT DEFAULT 0,
    total_portraits INT DEFAULT 0,
    duration_seconds INT,
    UNIQUE INDEX idx_crawl_date (crawl_date)
) ENGINE=InnoDB;
"@

$SQL | & mysql --user=root --password

# Save credentials
$CredFile = "modules\AE6E66\configuration\.db-credentials"
$CredContent = @"
db.name=$DB_NAME
db.user=$DB_USER
db.pass=$DB_PASS
db.host=localhost
db.port=3306
"@
Set-Content -Path $CredFile -Value $CredContent
icacls $CredFile /inheritance:r /grant:r "$($env:USERNAME):(R)" "BUILTIN\Administrators:(F)" | Out-Null

Write-Host "-- : [AE6E66] Database $DB_NAME created."
Write-Host "-- : [AE6E66] User: $DB_USER (SELECT, INSERT, UPDATE only)"
Write-Host "-- : [AE6E66] Credentials: $CredFile (restricted ACL)"
