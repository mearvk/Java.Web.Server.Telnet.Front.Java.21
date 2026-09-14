#!/bin/bash
# AE6E66 — Local Server Configuration for macOS
# Configures the built-in macOS Postfix for static IP local sending.
# Prerequisites: run install-postfix-macos.sh first.
set -euo pipefail

DOMAIN="${1:-lauradei.us}"
HOSTNAME="mail.${DOMAIN}"
STATIC_IP="${2:-$(ipconfig getifaddr en0 2>/dev/null || echo '127.0.0.1')}"

# Validate IP
if ! [[ "${STATIC_IP}" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "ERROR: Invalid IP address: ${STATIC_IP}"
    exit 1
fi

echo "-- : [AE6E66] macOS Local Server Configuration"
echo "-- : [AE6E66] Domain: ${DOMAIN} | Hostname: ${HOSTNAME} | IP: ${STATIC_IP}"

# Core identity
sudo postconf -e "myhostname = ${HOSTNAME}"
sudo postconf -e "mydomain = ${DOMAIN}"
sudo postconf -e "myorigin = \$mydomain"

# Listen on loopback + static IP
sudo postconf -e "inet_interfaces = 127.0.0.1, ${STATIC_IP}"
sudo postconf -e "inet_protocols = ipv4"

# Local destinations
sudo postconf -e "mydestination = \$myhostname, localhost.\$mydomain, localhost, \$mydomain"

# Direct delivery
sudo postconf -e "relayhost ="
sudo postconf -e "mynetworks = 127.0.0.0/8, ${STATIC_IP}/32"

# Relay restrictions
sudo postconf -e "smtpd_relay_restrictions = permit_mynetworks, reject_unauth_destination"
sudo postconf -e "smtpd_recipient_restrictions = permit_mynetworks, reject_unauth_destination"
sudo postconf -e "smtpd_helo_required = yes"

# TLS 1.2+
sudo postconf -e "smtp_tls_security_level = encrypt"
sudo postconf -e "smtp_tls_mandatory_protocols = >=TLSv1.2"
sudo postconf -e "smtp_tls_mandatory_ciphers = high"
sudo postconf -e "smtp_tls_loglevel = 1"

# Rate limits
sudo postconf -e "smtp_destination_rate_delay = 2s"
sudo postconf -e "smtp_destination_concurrency_limit = 2"

# Header cleanup
sudo postconf -e "header_checks = regexp:/etc/postfix/header_checks"
cat <<'HEADER' | sudo tee /etc/postfix/header_checks > /dev/null
/^Received:.*127\.0\.0\.1/    IGNORE
/^Received:.*localhost/        IGNORE
HEADER

# Reload Postfix
sudo postfix reload 2>/dev/null || sudo postfix start

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo " AE6E66 — macOS Local Server Configured"
echo "═══════════════════════════════════════════════════════════════"
echo " Bound: ${STATIC_IP}:25 | Direct MX | TLS 1.2+ | Rate-limited"
echo ""
echo " DNS Records Required:"
echo "   A     mail.${DOMAIN} -> ${STATIC_IP}"
echo "   MX    ${DOMAIN} -> mail.${DOMAIN} (priority 10)"
echo "   TXT   ${DOMAIN}  \"v=spf1 ip4:${STATIC_IP} -all\""
echo "═══════════════════════════════════════════════════════════════"
