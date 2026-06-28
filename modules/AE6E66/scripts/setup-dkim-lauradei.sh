#!/bin/bash
# AE6E66 — DKIM + SPF + DMARC Setup
# Server ID: mail.lauradei.us @ 45.32.31.139
# Target OS: Japanese locale VPS (chance and luck install)
# Installs opendkim, generates 2048-bit keys, configures Postfix for DKIM signing.
set -euo pipefail

DOMAIN="lauradei.us"
HOSTNAME="mail.lauradei.us"
STATIC_IP="45.32.31.139"
SELECTOR="ae6e66"
DKIM_DIR="/etc/opendkim/keys/${DOMAIN}"

echo "-- : [AE6E66] Setting up DKIM for ${HOSTNAME} @ ${STATIC_IP}"

# Detect Japanese locale
if locale -a 2>/dev/null | grep -qi "ja_JP"; then
    export LANG=ja_JP.UTF-8
    echo "-- : [AE6E66] Japanese locale detected"
fi

# Install
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

# Generate DKIM 2048-bit key pair
sudo mkdir -p "${DKIM_DIR}"
sudo opendkim-genkey -b 2048 -d "${DOMAIN}" -D "${DKIM_DIR}" -s "${SELECTOR}" -v
sudo chown -R opendkim:opendkim /etc/opendkim
sudo chmod 700 /etc/opendkim/keys
sudo chmod 600 "${DKIM_DIR}/${SELECTOR}.private"
sudo chmod 644 "${DKIM_DIR}/${SELECTOR}.txt"

# opendkim config — strict signing
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
Socket                  local:/run/opendkim/opendkim.sock
PidFile                 /run/opendkim/opendkim.pid
UMask                   007
UserID                  opendkim
RequireSafeKeys         yes
EOF

# Create run directory
sudo mkdir -p /run/opendkim
sudo chown opendkim:opendkim /run/opendkim
sudo chmod 750 /run/opendkim

# opendkim config permissions
sudo chmod 644 /etc/opendkim.conf

# Postfix main config — server ID: mail.lauradei.us
sudo postconf -e "myhostname = ${HOSTNAME}"
sudo postconf -e "mydomain = ${DOMAIN}"
sudo postconf -e "myorigin = \$mydomain"
sudo postconf -e "inet_interfaces = 127.0.0.1, ${STATIC_IP}"
sudo postconf -e "inet_protocols = ipv4"
sudo postconf -e "mydestination = ${HOSTNAME}, localhost.${DOMAIN}, localhost, ${DOMAIN}"
sudo postconf -e "relayhost ="
sudo postconf -e "mynetworks = 127.0.0.0/8, ${STATIC_IP}/32"

# Relay restrictions — no open relay
sudo postconf -e "smtpd_relay_restrictions = permit_mynetworks, reject_unauth_destination"
sudo postconf -e "smtpd_recipient_restrictions = permit_mynetworks, reject_unauth_destination"
sudo postconf -e "smtpd_helo_required = yes"
sudo postconf -e "smtpd_helo_restrictions = reject_invalid_helo_hostname, reject_non_fqdn_helo_hostname"

# TLS outbound — enforce TLS 1.2+
sudo postconf -e "smtp_tls_security_level = encrypt"
sudo postconf -e "smtp_tls_CAfile = /etc/ssl/certs/ca-certificates.crt"
sudo postconf -e "smtp_tls_mandatory_protocols = >=TLSv1.2"
sudo postconf -e "smtp_tls_mandatory_ciphers = high"
sudo postconf -e "smtp_tls_loglevel = 1"

# DKIM milter — use Unix socket (faster, no network exposure)
sudo postconf -e "milter_default_action = accept"
sudo postconf -e "milter_protocol = 6"
sudo postconf -e "smtpd_milters = unix:/run/opendkim/opendkim.sock"
sudo postconf -e "non_smtpd_milters = unix:/run/opendkim/opendkim.sock"

# Rate limiting
sudo postconf -e "smtp_destination_rate_delay = 2s"
sudo postconf -e "smtp_destination_concurrency_limit = 2"

# Header cleanup — strip internal IPs
sudo postconf -e "header_checks = regexp:/etc/postfix/header_checks"
cat <<'HEADER' | sudo tee /etc/postfix/header_checks > /dev/null
/^Received:.*127\.0\.0\.1/    IGNORE
/^Received:.*localhost/        IGNORE
HEADER
sudo chmod 644 /etc/postfix/header_checks

# Add postfix to opendkim group for socket access
sudo usermod -aG opendkim postfix

# Restrict config permissions
sudo chmod 644 /etc/postfix/main.cf

# Restart services
sudo systemctl restart opendkim
sudo systemctl restart postfix

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo " AE6E66 — mail.lauradei.us @ ${STATIC_IP}"
echo " Server ID: ${HOSTNAME}"
echo " Target: Japanese VPS (chance/luck)"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo " DNS Records Required:"
echo ""
echo " 1. A record:   mail.lauradei.us -> ${STATIC_IP}"
echo " 2. MX record:  lauradei.us -> mail.lauradei.us (priority 10)"
echo " 3. SPF (TXT on ${DOMAIN}):"
echo "    v=spf1 ip4:${STATIC_IP} a:${HOSTNAME} -all"
echo " 4. DKIM (TXT: ${SELECTOR}._domainkey.${DOMAIN}):"
sudo cat "${DKIM_DIR}/${SELECTOR}.txt"
echo " 5. DMARC (TXT: _dmarc.${DOMAIN}):"
echo "    v=DMARC1; p=quarantine; rua=mailto:postmaster@${DOMAIN}; pct=100"
echo " 6. PTR (reverse DNS for ${STATIC_IP}):"
echo "    ${STATIC_IP} -> ${HOSTNAME}"
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo " Security:"
echo "   - DKIM signing via Unix socket (no inet exposure)"
echo "   - TLS 1.2+ enforced for all outbound"
echo "   - HELO validation enabled"
echo "   - Open relay rejected"
echo "   - DMARC policy: quarantine (upgrade to reject after testing)"
echo "   - Key permissions: 600 (private), 644 (public)"
echo "═══════════════════════════════════════════════════════════════"
echo " DKIM private: ${DKIM_DIR}/${SELECTOR}.private"
echo " DKIM public:  ${DKIM_DIR}/${SELECTOR}.txt"
echo " Postfix HELO: ${HOSTNAME}"
echo "═══════════════════════════════════════════════════════════════"
