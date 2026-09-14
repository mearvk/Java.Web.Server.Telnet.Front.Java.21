#!/bin/bash
# AE6E66 — Postfix Install for macOS
# Uses Homebrew for package management. macOS ships with Postfix but it's disabled.
set -euo pipefail

DOMAIN="${1:-lauradei.us}"
HOSTNAME="mail.${DOMAIN}"
FROM="contact@${DOMAIN}"

echo "-- : [AE6E66] macOS Mail Server Setup"
echo "-- : [AE6E66] Domain: ${DOMAIN} | Hostname: ${HOSTNAME}"

# Check for Homebrew
if ! command -v brew &>/dev/null; then
    echo "ERROR: Homebrew not found. Install from https://brew.sh"
    exit 1
fi

# macOS ships with Postfix — just configure and enable it
# Install opendkim via Homebrew for DKIM signing
brew install opendkim 2>/dev/null || true

# Postfix config — macOS uses /etc/postfix/main.cf
POSTFIX_CF="/etc/postfix/main.cf"

echo "-- : [AE6E66] Configuring Postfix at ${POSTFIX_CF}"

sudo postconf -e "myhostname = ${HOSTNAME}"
sudo postconf -e "mydomain = ${DOMAIN}"
sudo postconf -e "myorigin = \$mydomain"
sudo postconf -e "inet_interfaces = loopback-only"
sudo postconf -e "inet_protocols = ipv4"
sudo postconf -e "mydestination = \$myhostname, localhost.\$mydomain, localhost"
sudo postconf -e "relayhost ="
sudo postconf -e "mynetworks = 127.0.0.0/8"

# TLS — enforce 1.2+
sudo postconf -e "smtp_tls_security_level = encrypt"
sudo postconf -e "smtp_tls_mandatory_protocols = >=TLSv1.2"
sudo postconf -e "smtp_tls_mandatory_ciphers = high"
sudo postconf -e "smtp_tls_loglevel = 1"

# Relay restrictions
sudo postconf -e "smtpd_relay_restrictions = permit_mynetworks, reject_unauth_destination"
sudo postconf -e "smtpd_recipient_restrictions = permit_mynetworks, reject_unauth_destination"

# Rate limiting
sudo postconf -e "smtp_destination_rate_delay = 2s"
sudo postconf -e "smtp_destination_concurrency_limit = 2"

# Header cleanup
sudo postconf -e "header_checks = regexp:/etc/postfix/header_checks"
cat <<'HEADER' | sudo tee /etc/postfix/header_checks > /dev/null
/^Received:.*127\.0\.0\.1/    IGNORE
/^Received:.*localhost/        IGNORE
HEADER

# Enable Postfix via launchd (macOS way)
sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.postfix.master.plist 2>/dev/null || true
sudo postfix start 2>/dev/null || sudo postfix reload

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo " AE6E66 — macOS Mail Setup Complete"
echo "═══════════════════════════════════════════════════════════════"
echo " Postfix:   enabled via launchd"
echo " Domain:    ${DOMAIN}"
echo " From:      ${FROM}"
echo " TLS:       1.2+ enforced"
echo " Test:      echo 'test' | mail -s 'AE6E66 Test' you@example.com"
echo "═══════════════════════════════════════════════════════════════"
