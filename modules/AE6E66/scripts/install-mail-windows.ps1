# AE6E66 — Mail Server Install for Windows (hMailServer + stunnel)
# PowerShell script. Run as Administrator.
# Windows does not ship with Postfix; uses hMailServer (free) + stunnel for TLS.

#Requires -RunAsAdministrator
$ErrorActionPreference = "Stop"

$DOMAIN = "lauradei.us"
$FROM = "contact@lauradei.us"
$HMAILSERVER_URL = "https://www.hmailserver.com/download"

Write-Host "-- : [AE6E66] Windows Mail Server Setup" -ForegroundColor Green
Write-Host "-- : [AE6E66] Domain: $DOMAIN | From: $FROM"

# Check if Chocolatey is available for stunnel
if (Get-Command choco -ErrorAction SilentlyContinue) {
    Write-Host "-- : [AE6E66] Installing stunnel via Chocolatey..."
    choco install stunnel -y
} else {
    Write-Host "-- : [AE6E66] WARNING: Chocolatey not found. Install stunnel manually from https://www.stunnel.org/downloads.html"
}

# Create AE6E66 mail config directory
$ConfigDir = "$env:ProgramData\AE6E66\mail"
New-Item -ItemType Directory -Force -Path $ConfigDir | Out-Null

# Generate stunnel config for TLS outbound
$StunnelConf = @"
; AE6E66 stunnel config — TLS wrapper for outbound SMTP
[smtp-out]
client = yes
accept = 127.0.0.1:2525
connect = localhost:25
protocol = smtp
protocolVersion = TLSv1.2
"@
Set-Content -Path "$ConfigDir\stunnel-smtp.conf" -Value $StunnelConf

# Write send-mail.ps1 helper
$SendMailScript = @"
# AE6E66 — Send mail via local SMTP (Windows)
param(
    [Parameter(Mandatory)][string]`$To,
    [Parameter(Mandatory)][string]`$Subject,
    [Parameter(Mandatory)][string]`$Body
)

`$ErrorActionPreference = "Stop"

# Validate email
if (`$To -notmatch '^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$') {
    throw "Invalid email address: `$To"
}
# Prevent header injection
`$Subject = `$Subject -replace '[\r\n]', ''

`$SmtpServer = "localhost"
`$SmtpPort = 25
`$From = "$FROM"

`$Message = New-Object System.Net.Mail.MailMessage(`$From, `$To, `$Subject, `$Body)
`$Message.Headers.Add("X-Mailer", "AE6E66/1.2")

`$Smtp = New-Object System.Net.Mail.SmtpClient(`$SmtpServer, `$SmtpPort)
`$Smtp.EnableSsl = `$false
`$Smtp.Timeout = 30000
`$Smtp.Send(`$Message)

Write-Host "-- : [AE6E66] Sent to `$To"
"@
Set-Content -Path "$ConfigDir\send-mail.ps1" -Value $SendMailScript

# Restrict permissions on config dir
icacls $ConfigDir /inheritance:r /grant:r "BUILTIN\Administrators:(OI)(CI)F" "NT AUTHORITY\SYSTEM:(OI)(CI)F" | Out-Null

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host " AE6E66 — Windows Mail Setup Complete"
Write-Host "═══════════════════════════════════════════════════════════════"
Write-Host " Config:     $ConfigDir"
Write-Host " Send mail:  powershell $ConfigDir\send-mail.ps1 -To x@y.com -Subject 'Test' -Body 'Hello'"
Write-Host ""
Write-Host " Next steps:"
Write-Host "   1. Install hMailServer from $HMAILSERVER_URL"
Write-Host "   2. Configure domain: $DOMAIN"
Write-Host "   3. Set from address: $FROM"
Write-Host "   4. For TLS: start stunnel with $ConfigDir\stunnel-smtp.conf"
Write-Host "═══════════════════════════════════════════════════════════════"
