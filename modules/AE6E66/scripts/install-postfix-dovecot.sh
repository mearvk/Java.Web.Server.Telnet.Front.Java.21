#!/bin/bash
# AE6E66 — Postfix/Dovecot Installation Script
# Configured for basic LOCAL USE sending to known domains and static IPs.
set -euo pipefail

echo "-- : [AE6E66] Installing Postfix and Dovecot..."

if command -v apt &>/dev/null; then
    sudo DEBIAN_FRONTEND=noninteractive apt update
    sudo DEBIAN_FRONTEND=noninteractive apt install -y postfix dovecot-core dovecot-imapd mailutils
elif command -v dnf &>/dev/null; then
    sudo dnf install -y postfix dovecot mailx
elif command -v yum &>/dev/null; then
    sudo yum install -y postfix dovecot mailx
else
    echo "ERROR: Unsupported package manager. Install postfix and dovecot manually."
    exit 1
fi

# Enable and start services
sudo systemctl enable postfix dovecot
sudo systemctl start postfix dovecot

# Postfix config — local sending to external domains (direct delivery, no relay)
sudo postconf -e "myhostname = mail.lauradei.us"
sudo postconf -e "mydomain = lauradei.us"
sudo postconf -e "myorigin = \$mydomain"
sudo postconf -e "inet_interfaces = loopback-only"
sudo postconf -e "inet_protocols = ipv4"
sudo postconf -e "mydestination = \$myhostname, localhost.\$mydomain, localhost"
sudo postconf -e "relayhost ="
sudo postconf -e "mynetworks = 127.0.0.0/8"

# TLS — enforce for outbound where possible
sudo postconf -e "smtp_tls_security_level = encrypt"
sudo postconf -e "smtp_tls_CAfile = /etc/ssl/certs/ca-certificates.crt"
sudo postconf -e "smtp_tls_loglevel = 1"
sudo postconf -e "smtp_tls_mandatory_protocols = >=TLSv1.2"
sudo postconf -e "smtp_tls_mandatory_ciphers = high"

# Restrict relay — no open relay
sudo postconf -e "smtpd_relay_restrictions = permit_mynetworks, reject_unauth_destination"
sudo postconf -e "smtpd_recipient_restrictions = permit_mynetworks, reject_unauth_destination"

# Rate limiting
sudo postconf -e "smtp_destination_rate_delay = 2s"
sudo postconf -e "smtp_destination_concurrency_limit = 2"

# Direct MX lookup delivery
sudo postconf -e "default_transport = smtp"
sudo postconf -e "relay_transport = smtp"

# Restrict permissions on config
sudo chmod 644 /etc/postfix/main.cf
sudo chmod 755 /etc/postfix

sudo systemctl restart postfix

echo "-- : [AE6E66] Postfix installed — direct delivery mode (MX lookup)."
echo "-- : [AE6E66] Sends from: contact@lauradei.us via localhost:25"
echo "-- : [AE6E66] TLS enforced for outbound connections (>=TLSv1.2)"
echo "-- : [AE6E66] Verify: echo 'test' | mail -s 'AE6E66 Test' your@email.com"
