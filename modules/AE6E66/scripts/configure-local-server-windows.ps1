# AE6E66 — Local Server Configuration for Windows
# PowerShell script. Run as Administrator.
# Configures hMailServer or built-in SMTP for local sending.

#Requires -RunAsAdministrator
$ErrorActionPreference = "Stop"

param(
    [string]$Domain = "lauradei.us",
    [string]$StaticIP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -notlike "*Loopback*" -and $_.PrefixOrigin -ne "WellKnown" } | Select-Object -First 1 -ExpandProperty IPAddress)
)

$Hostname = "mail.$Domain"

Write-Host "-- : [AE6E66] Windows Local Server Configuration" -ForegroundColor Green
Write-Host "-- : [AE6E66] Domain: $Domain | Hostname: $Hostname | IP: $StaticIP"

# Validate IP
if ($StaticIP -notmatch '^\d+\.\d+\.\d+\.\d+$') {
    Write-Error "Invalid IP address: $StaticIP"
    exit 1
}

# Configure Windows SMTP (IIS SMTP or hMailServer)
$ConfigDir = "$env:ProgramData\AE6E66\mail"
New-Item -ItemType Directory -Force -Path $ConfigDir | Out-Null

# Write server config
$ServerConfig = @"
; AE6E66 Local Server Configuration
; Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
[server]
hostname=$Hostname
domain=$Domain
static_ip=$StaticIP
from=contact@$Domain
port=25

[security]
tls_minimum=TLSv1.2
relay_restriction=reject_unauth_destination
helo_required=true
rate_limit_seconds=2
max_concurrent=2

[headers]
strip_internal_ip=true
"@
Set-Content -Path "$ConfigDir\server.conf" -Value $ServerConfig

# Windows Firewall — allow outbound SMTP
New-NetFirewallRule -DisplayName "AE6E66 SMTP Out" -Direction Outbound -Protocol TCP -RemotePort 25,587 -Action Allow -ErrorAction SilentlyContinue | Out-Null

# Restrict config permissions
icacls $ConfigDir /inheritance:r /grant:r "BUILTIN\Administrators:(OI)(CI)F" "NT AUTHORITY\SYSTEM:(OI)(CI)F" | Out-Null

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host " AE6E66 — Windows Local Server Configured"
Write-Host "═══════════════════════════════════════════════════════════════"
Write-Host " Config:  $ConfigDir\server.conf"
Write-Host " IP:      $StaticIP"
Write-Host " Domain:  $Domain"
Write-Host ""
Write-Host " DNS Records Required:"
Write-Host "   A     mail.$Domain -> $StaticIP"
Write-Host "   MX    $Domain -> mail.$Domain (priority 10)"
Write-Host "   TXT   $Domain `"v=spf1 ip4:$StaticIP -all`""
Write-Host "═══════════════════════════════════════════════════════════════"
