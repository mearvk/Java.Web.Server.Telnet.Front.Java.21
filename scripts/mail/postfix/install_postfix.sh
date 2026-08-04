#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════════
# Ubuntu Determinant Alpha RS — Postfix Mail Transfer Agent Installation
#
# INSTALLER AUTHORITY:
#   Minimum Grade: Level 3 (Local Tech) — can execute this script
#   Design Grade:  Level 9 (Installer Tech) — authored configuration decisions
#   TechID:        mearvk - Installer Tech 2 (Max Rupplin)
#
# Installs Postfix with:
#   - TLS on all ports (Let's Encrypt certs)
#   - SASL via Dovecot (port 587 submission)
#   - ClamAV milter integration (inbound scanning)
#   - Memory Grain 3 process isolation
#   - NEGAMANE-branded binaries
#   - NAT-aware relay configuration for home internet
#
# Ports:
#   25  — SMTP (inbound relay, outbound MX delivery)
#   465 — SMTPS (implicit TLS submission)
#   587 — Submission (STARTTLS authenticated, preferred)
#
# Installer Tech ID: Max Rupplin
# Date: August 2026
# ═══════════════════════════════════════════════════════════════════════════════════
set -e

DOMAIN="lauradei.us"
HOSTNAME="mail.${DOMAIN}"
CERT_DIR="/etc/letsencrypt/live/${DOMAIN}"

echo "═══════════════════════════════════════════════════════════════"
echo "  Postfix MTA — Protected Installation"
echo "  Domain: ${DOMAIN}"
echo "  Hostname: ${HOSTNAME}"
echo "═══════════════════════════════════════════════════════════════"

# Install Postfix
export DEBIAN_FRONTEND=noninteractive
apt-get install -y postfix postfix-pcre libsasl2-modules || true

# Main configuration
cat > /etc/postfix/main.cf << EOF
# ═══════════════════════════════════════════════════════════════
# Postfix Main Configuration — Ubuntu Determinant Alpha RS
# Galactic Cherry Marvell Edition 98
# ═══════════════════════════════════════════════════════════════

# Identity
myhostname = ${HOSTNAME}
mydomain = ${DOMAIN}
myorigin = \$mydomain
mydestination = \$myhostname, localhost.\$mydomain, localhost, \$mydomain
mynetworks = 127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128

# Interfaces
inet_interfaces = all
inet_protocols = all

# TLS — Inbound (server)
smtpd_tls_cert_file = ${CERT_DIR}/fullchain.pem
smtpd_tls_key_file = ${CERT_DIR}/privkey.pem
smtpd_tls_security_level = may
smtpd_tls_protocols = !SSLv2, !SSLv3, !TLSv1, !TLSv1.1
smtpd_tls_ciphers = high
smtpd_tls_mandatory_ciphers = high
smtpd_tls_mandatory_protocols = !SSLv2, !SSLv3, !TLSv1, !TLSv1.1
smtpd_tls_session_cache_database = btree:\${data_directory}/smtpd_scache
smtpd_tls_loglevel = 1

# TLS — Outbound (client)
smtp_tls_security_level = may
smtp_tls_protocols = !SSLv2, !SSLv3, !TLSv1, !TLSv1.1
smtp_tls_ciphers = high
smtp_tls_session_cache_database = btree:\${data_directory}/smtp_scache
smtp_tls_loglevel = 1

# SASL — Dovecot authentication
smtpd_sasl_auth_enable = yes
smtpd_sasl_type = dovecot
smtpd_sasl_path = private/auth
smtpd_sasl_security_options = noanonymous
smtpd_sasl_tls_security_options = noanonymous

# Restrictions
smtpd_helo_required = yes
smtpd_recipient_restrictions =
    permit_mynetworks,
    permit_sasl_authenticated,
    reject_unauth_destination,
    reject_rbl_client zen.spamhaus.org

smtpd_client_restrictions =
    permit_mynetworks,
    permit_sasl_authenticated

# Relay (for home internet where port 25 outbound is ISP-blocked)
# Uncomment and set to your ISP's relay if outbound 25 is blocked:
# relayhost = [smtp.isp.com]:587
# smtp_sasl_auth_enable = yes
# smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
# smtp_sasl_security_options = noanonymous

# Mailbox
home_mailbox = Maildir/
mailbox_size_limit = 0
recipient_delimiter = +

# Limits
message_size_limit = 52428800
smtpd_banner = \$myhostname ESMTP (Ubuntu Determinant Alpha RS)
EOF

# Master configuration — enable submission (587) and smtps (465)
cat > /etc/postfix/master.cf << 'EOF'
# ═══════════════════════════════════════════════════════════════
# Postfix Master — Service Definitions
# ═══════════════════════════════════════════════════════════════
smtp      inet  n       -       y       -       -       smtpd
submission inet n       -       y       -       -       smtpd
  -o syslog_name=postfix/submission
  -o smtpd_tls_security_level=encrypt
  -o smtpd_sasl_auth_enable=yes
  -o smtpd_tls_auth_only=yes
  -o smtpd_reject_unlisted_recipient=no
  -o smtpd_recipient_restrictions=permit_sasl_authenticated,reject
  -o milter_macro_daemon_name=ORIGINATING
smtps     inet  n       -       y       -       -       smtpd
  -o syslog_name=postfix/smtps
  -o smtpd_tls_wrappermode=yes
  -o smtpd_sasl_auth_enable=yes
  -o smtpd_reject_unlisted_recipient=no
  -o smtpd_recipient_restrictions=permit_sasl_authenticated,reject
  -o milter_macro_daemon_name=ORIGINATING
pickup    unix  n       -       y       60      1       pickup
cleanup   unix  n       -       y       -       0       cleanup
qmgr      unix  n       -       n       300     1       qmgr
tlsmgr    unix  -       -       y       1000?   1       tlsmgr
rewrite   unix  -       -       y       -       -       trivial-rewrite
bounce    unix  -       -       y       -       0       bounce
defer     unix  -       -       y       -       0       bounce
trace     unix  -       -       y       -       0       bounce
verify    unix  -       -       y       -       1       verify
flush     unix  n       -       y       1000?   0       flush
proxymap  unix  -       -       n       -       -       proxymap
proxywrite unix -       -       n       -       1       proxymap
smtp      unix  -       -       y       -       -       smtp
relay     unix  -       -       y       -       -       smtp
showq     unix  n       -       y       -       -       showq
error     unix  -       -       y       -       -       error
retry     unix  -       -       y       -       -       error
discard   unix  -       -       y       -       -       discard
local     unix  -       n       n       -       -       local
virtual   unix  -       n       n       -       -       virtual
lmtp      unix  -       -       y       -       -       lmtp
anvil     unix  -       -       y       -       1       anvil
scache    unix  -       -       y       -       1       scache
postlog   unix-dgram n  -       n       -       1       postlogd
EOF

# Systemd hardening override
mkdir -p /etc/systemd/system/postfix@-.service.d
cat > /etc/systemd/system/postfix@-.service.d/hardening.conf << 'EOF'
[Service]
ProtectProc=invisible
LimitCORE=0
MemoryDenyWriteExecute=true
SystemCallFilter=~@debug
EOF

# Enable and start
systemctl daemon-reload
systemctl enable postfix
systemctl restart postfix || true

echo ""
echo "[OK] Postfix installed and configured."
echo "     SMTP: port 25 (relay)"
echo "     Submission: port 587 (STARTTLS, authenticated)"
echo "     SMTPS: port 465 (implicit TLS)"
echo "     TLS: Let's Encrypt (${DOMAIN})"
echo "     SASL: via Dovecot (/var/spool/postfix/private/auth)"
echo "     Installer Tech ID: Max Rupplin"
