#!/bin/bash
# AE6E66 — DKIM + SPF + Domain Relay Setup
# Server ID: mail.lauradei.us @ 45.32.31.139
# Target OS: Japanese locale VPS (chance and luck install)
# Installs opendkim, generates keys, configures Postfix for DKIM signing.

set -e

DOMAIN="lauradei.us"
HOSTNAME="mail.lauradei.us"
STATIC_IP="45.32.31.139"
SELECTOR="ae6e66"
DKIM_DIR="/etc/opendkim/keys/${DOMAIN}"

echo "-- : [AE6E66] Setting up DKIM for ${HOSTNAME} @ ${STATIC_IP}"
echo "-- : [AE6E66] Target: Japanese VPS (chance/luck install)"

# Detect Japanese locale and set UTF-8 if needed
if locale -a 2>/dev/null | grep -qi "ja_JP"; then
    export LANG=ja_JP.UTF-8
    echo "-- : [AE6E66] Japanese locale detected"
fi

# Install — supports apt (Debian/Ubuntu) and yum/dnf (CentOS/Amazon Linux JP)
if command -v apt &>/dev/null; then
    sudo DEBIAN_FRONTEND=noninteractive apt update
    sudo DEBIAN_FRONTEND=noninteractive apt install -y postfix dovecot-core opendkim opendkim-tools mailutils
elif command -v dnf &>/dev/null; then
    sudo dnf install -y postfix dovecot opendkim opendkim-tools mailx
elif command -v yum &>/dev/null; then
    sudo yum install -y postfix dovecot opendkim opendkim-tools mailx
elif command -v pacman &>/dev/null; then
    sudo pacman -Sy --noconfirm postfix dovecot opendkim
else
    echo "ERROR: Unsupported package manager."
    exit 1
fi

# Enable services
sudo systemctl enable postfix dovecot opendkim
sudo systemctl start dovecot

# Generate DKIM key pair
sudo mkdir -p "${DKIM_DIR}"
sudo opendkim-genkey -b 2048 -d "${DOMAIN}" -D "${DKIM_DIR}" -s "${SELECTOR}" -v
sudo chown -R opendkim:opendkim /etc/opendkim
sudo chmod 600 "${DKIM_DIR}/${SELECTOR}.private"

# opendkim config
sudo tee /etc/opendkim.conf > /dev/null <<EOF
AutoRestart             Yes
AutoRestartRate         10/1h
Syslog                  yes
SyslogSuccess           yes
LogWhy                  yes
Canonicalization        relaxed/simple
Mode                    sv
SubDomains              no
OversignHeaders         From
Domain                  ${DOMAIN}
Selector                ${SELECTOR}
KeyFile                 ${DKIM_DIR}/${SELECTOR}.private
Socket                  inet:8891@localhost
PidFile                 /run/opendkim/opendkim.pid
UMask                   007
UserID                  opendkim
EOF

# Postfix main config — server ID: mail.lauradei.us
sudo postconf -e "myhostname = ${HOSTNAME}"
sudo postconf -e "mydomain = ${DOMAIN}"
sudo postconf -e "myorigin = \$mydomain"
sudo postconf -e "inet_interfaces = 127.0.0.1, ${STATIC_IP}"
sudo postconf -e "inet_protocols = ipv4"
sudo postconf -e "mydestination = ${HOSTNAME}, localhost.${DOMAIN}, localhost, ${DOMAIN}"
sudo postconf -e "relayhost ="
sudo postconf -e "mynetworks = 127.0.0.0/8, ${STATIC_IP}/32"

# TLS outbound
sudo postconf -e "smtp_tls_security_level = may"
sudo postconf -e "smtp_tls_CAfile = /etc/ssl/certs/ca-certificates.crt"
sudo postconf -e "smtp_tls_loglevel = 1"

# DKIM milter
sudo postconf -e "milter_default_action = accept"
sudo postconf -e "milter_protocol = 6"
sudo postconf -e "smtpd_milters = inet:localhost:8891"
sudo postconf -e "non_smtpd_milters = inet:localhost:8891"

# Rate limiting (polite sender)
sudo postconf -e "smtp_destination_rate_delay = 2s"
sudo postconf -e "smtp_destination_concurrency_limit = 2"

# Header cleanup
sudo postconf -e "header_checks = regexp:/etc/postfix/header_checks"
echo "/^Received:.*127\\.0\\.0\\.1/    IGNORE" | sudo tee /etc/postfix/header_checks > /dev/null

# Restart
sudo systemctl restart opendkim
sudo systemctl restart postfix

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo " AE6E66 — mail.lauradei.us @ ${STATIC_IP}"
echo " Server ID: ${HOSTNAME}"
echo " Install target: Japanese VPS (chance/luck)"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo " DNS Records Required:"
echo ""
echo " 1. A record:   mail.lauradei.us -> ${STATIC_IP}"
echo ""
echo " 2. MX record:  lauradei.us -> mail.lauradei.us (priority 10)"
echo ""
echo " 3. SPF (TXT on ${DOMAIN}):"
echo "    v=spf1 ip4:${STATIC_IP} a:${HOSTNAME} ~all"
echo ""
echo " 4. DKIM (TXT: ${SELECTOR}._domainkey.${DOMAIN}):"
sudo cat "${DKIM_DIR}/${SELECTOR}.txt"
echo ""
echo " 5. DMARC (TXT: _dmarc.${DOMAIN}):"
echo "    v=DMARC1; p=none; rua=mailto:postmaster@${DOMAIN}"
echo ""
echo " 6. PTR (reverse DNS for ${STATIC_IP}):"
echo "    ${STATIC_IP} -> ${HOSTNAME}"
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo " DKIM private: ${DKIM_DIR}/${SELECTOR}.private"
echo " DKIM public:  ${DKIM_DIR}/${SELECTOR}.txt"
echo " Postfix HELO: ${HOSTNAME}"
echo "═══════════════════════════════════════════════════════════════"
