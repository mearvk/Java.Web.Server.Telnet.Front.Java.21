#!/bin/bash
# AE6E66 — Postfix/Dovecot Installation Script
# Configured for basic LOCAL USE sending to known domains and static IPs.

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
sudo postconf -e "myhostname = mail.mearvk.us"
sudo postconf -e "mydomain = mearvk.us"
sudo postconf -e "myorigin = \$mydomain"
sudo postconf -e "inet_interfaces = loopback-only"
sudo postconf -e "inet_protocols = ipv4"
sudo postconf -e "mydestination = \$myhostname, localhost.\$mydomain, localhost"
sudo postconf -e "relayhost ="
sudo postconf -e "mynetworks = 127.0.0.0/8"
sudo postconf -e "smtp_tls_security_level = may"
sudo postconf -e "smtp_tls_loglevel = 1"

# Allow sending to any destination (direct MX lookup)
sudo postconf -e "default_transport = smtp"
sudo postconf -e "relay_transport = smtp"

sudo systemctl restart postfix

echo "-- : [AE6E66] Postfix installed — direct delivery mode (MX lookup)."
echo "-- : [AE6E66] Sends from: contact@mearvk.us via localhost:25"
echo "-- : [AE6E66] Verify: echo 'test' | mail -s 'AE6E66 Test' your@email.com"
