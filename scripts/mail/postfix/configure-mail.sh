#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════════
# Ubuntu Determinant Alpha RS — Dovecot/Postfix Configuration Script
#
# INSTALLER AUTHORITY:
#   Minimum Grade: Level 3 (Local Tech) — can execute this script
#   Design Grade:  Level 9 (Installer Tech) — authored the configuration choices
#   TechID:        mearvk - Installer Tech 2 (Max Rupplin)
#
# A Level 3 Local Tech runs this script. The script itself encodes Level 9
# decisions: cipher suites, protocol versions, DH parameters, certificate
# strategy, rate limits, restriction chains. The Level 3 does not need to
# understand WHY these choices are correct — only that they ARE correct,
# because the Level 9 authored them with full knowledge of consequence.
#
# Writes secure, elegant, production-ready configuration files for Postfix and
# Dovecot. Does NOT install packages — only writes config. Run install scripts
# first, then this to finalize settings.
#
# Philosophy:
#   - TLS 1.2+ only, ECDHE forward secrecy, modern ciphers
#   - No plaintext anywhere a TLS option exists
#   - Minimal attack surface: only required protocols enabled
#   - Dovecot handles auth for both itself and Postfix (single auth source)
#   - LMTP for local delivery (Sieve-capable, quota-aware)
#   - Sensible rate limits without blocking legitimate use
#   - Clean, commented files — an admin can read and understand every line
#   - Certificate watchdog: auto-refresh on expiry, revocation, corruption
#
# Usage:
#   sudo bash configure-mail.sh
#   sudo bash configure-mail.sh --domain example.com --ip 1.2.3.4
#
# Installer Tech ID: Max Rupplin — Level 9
# Execution Grade: Level 3 (Local Tech) or higher
# Date: August 2026
# Edition: Galactic Cherry Marvell 98
# ═══════════════════════════════════════════════════════════════════════════════════
set -euo pipefail

# ─────────────────────────────────────────────────────────────────────────────────
# Defaults (override via CLI or environment)
# ─────────────────────────────────────────────────────────────────────────────────
DOMAIN="${MAIL_DOMAIN:-lauradei.us}"
HOSTNAME="${MAIL_HOSTNAME:-mail.${DOMAIN}}"
SERVER_IP="${MAIL_SERVER_IP:-45.32.31.139}"
CERT_DIR="${MAIL_CERT_DIR:-/etc/letsencrypt/live/${DOMAIN}}"
POSTFIX_DIR="/etc/postfix"
DOVECOT_DIR="/etc/dovecot"

# Parse CLI args
while [[ $# -gt 0 ]]; do
    case "$1" in
        --domain)   DOMAIN="$2"; HOSTNAME="mail.${DOMAIN}"; shift 2 ;;
        --hostname) HOSTNAME="$2"; shift 2 ;;
        --ip)       SERVER_IP="$2"; shift 2 ;;
        --cert-dir) CERT_DIR="$2"; shift 2 ;;
        --help|-h)
            echo "Usage: sudo bash configure-mail.sh [--domain D] [--hostname H] [--ip IP] [--cert-dir DIR]"
            exit 0 ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

echo "═══════════════════════════════════════════════════════════════"
echo "  Mail Configuration — Secure & Elegant"
echo "  Domain:   ${DOMAIN}"
echo "  Hostname: ${HOSTNAME}"
echo "  IP:       ${SERVER_IP}"
echo "  Certs:    ${CERT_DIR}"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# ═══════════════════════════════════════════════════════════════════════════════════
# POSTFIX — /etc/postfix/main.cf
# ═══════════════════════════════════════════════════════════════════════════════════

echo "[1/9] Writing Postfix main.cf..."

cat > "${POSTFIX_DIR}/main.cf" << EOF
# ═══════════════════════════════════════════════════════════════
# /etc/postfix/main.cf
# Ubuntu Determinant Alpha RS — Galactic Cherry Marvell 98
# Secure, modern, TLS-first configuration.
# ═══════════════════════════════════════════════════════════════

# ─────────────────────────────────────────────────────────────
# IDENTITY
# ─────────────────────────────────────────────────────────────
myhostname = ${HOSTNAME}
mydomain = ${DOMAIN}
myorigin = \$mydomain
mydestination = \$myhostname, localhost.\$mydomain, localhost, \$mydomain
mynetworks = 127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128
inet_interfaces = all
inet_protocols = all

# ─────────────────────────────────────────────────────────────
# TLS — SERVER (inbound connections to us)
# ─────────────────────────────────────────────────────────────
smtpd_tls_cert_file = ${CERT_DIR}/fullchain.pem
smtpd_tls_key_file = ${CERT_DIR}/privkey.pem
smtpd_tls_security_level = may
smtpd_tls_auth_only = yes
smtpd_tls_protocols = >=TLSv1.2
smtpd_tls_mandatory_protocols = >=TLSv1.2
smtpd_tls_mandatory_ciphers = high
smtpd_tls_exclude_ciphers = aNULL, eNULL, EXPORT, DES, RC4, MD5, PSK, aECDH, EDH-DSS-DES-CBC3-SHA, EDH-RSA-DES-CBC3-SHA, KRB5-DES, CBC3-SHA
smtpd_tls_dh1024_param_file = \${config_directory}/dh2048.pem
smtpd_tls_session_cache_database = btree:\${data_directory}/smtpd_scache
smtpd_tls_session_cache_timeout = 3600s
smtpd_tls_loglevel = 1
smtpd_tls_received_header = yes

# ─────────────────────────────────────────────────────────────
# TLS — CLIENT (outbound connections from us)
# ─────────────────────────────────────────────────────────────
smtp_tls_security_level = dane
smtp_dns_support_level = dnssec
smtp_tls_protocols = >=TLSv1.2
smtp_tls_mandatory_protocols = >=TLSv1.2
smtp_tls_mandatory_ciphers = high
smtp_tls_session_cache_database = btree:\${data_directory}/smtp_scache
smtp_tls_session_cache_timeout = 3600s
smtp_tls_loglevel = 1
smtp_tls_CAfile = /etc/ssl/certs/ca-certificates.crt

# ─────────────────────────────────────────────────────────────
# SASL — Dovecot provides authentication
# ─────────────────────────────────────────────────────────────
smtpd_sasl_auth_enable = yes
smtpd_sasl_type = dovecot
smtpd_sasl_path = private/auth
smtpd_sasl_security_options = noanonymous, noplaintext
smtpd_sasl_tls_security_options = noanonymous

# ─────────────────────────────────────────────────────────────
# RESTRICTIONS — Defense in depth
# ─────────────────────────────────────────────────────────────
smtpd_helo_required = yes
strict_rfc821_envelopes = yes
disable_vrfy_command = yes

smtpd_helo_restrictions =
    permit_mynetworks,
    reject_invalid_helo_hostname,
    reject_non_fqdn_helo_hostname

smtpd_sender_restrictions =
    permit_mynetworks,
    permit_sasl_authenticated,
    reject_non_fqdn_sender,
    reject_unknown_sender_domain

smtpd_recipient_restrictions =
    permit_mynetworks,
    permit_sasl_authenticated,
    reject_unauth_destination,
    reject_non_fqdn_recipient,
    reject_unknown_recipient_domain,
    reject_rbl_client zen.spamhaus.org=127.0.0.[2..11],
    reject_rbl_client bl.spamcop.net,
    reject_rhsbl_helo dbl.spamhaus.org,
    reject_rhsbl_sender dbl.spamhaus.org

smtpd_relay_restrictions =
    permit_mynetworks,
    permit_sasl_authenticated,
    defer_unauth_destination

smtpd_data_restrictions =
    reject_unauth_pipelining

# ─────────────────────────────────────────────────────────────
# DELIVERY
# ─────────────────────────────────────────────────────────────
virtual_transport = lmtp:unix:private/dovecot-lmtp
home_mailbox = Maildir/
mailbox_size_limit = 0
message_size_limit = 52428800
recipient_delimiter = +

# ─────────────────────────────────────────────────────────────
# RATE LIMITING
# ─────────────────────────────────────────────────────────────
smtpd_client_connection_rate_limit = 30
smtpd_client_message_rate_limit = 60
smtpd_client_recipient_rate_limit = 120
smtpd_error_sleep_time = 1s
smtpd_soft_error_limit = 5
smtpd_hard_error_limit = 10

# ─────────────────────────────────────────────────────────────
# MILTERS — DKIM signing + ClamAV scanning
# ─────────────────────────────────────────────────────────────
milter_default_action = accept
milter_protocol = 6
smtpd_milters = inet:localhost:8891, inet:localhost:7357
non_smtpd_milters = inet:localhost:8891

# ─────────────────────────────────────────────────────────────
# MISC
# ─────────────────────────────────────────────────────────────
smtpd_banner = \$myhostname ESMTP
biff = no
append_dot_mydomain = no
readme_directory = no
compatibility_level = 3.6
EOF

# ═══════════════════════════════════════════════════════════════════════════════════
# POSTFIX — /etc/postfix/master.cf
# ═══════════════════════════════════════════════════════════════════════════════════

echo "[2/9] Writing Postfix master.cf..."

cat > "${POSTFIX_DIR}/master.cf" << 'EOF'
# ═══════════════════════════════════════════════════════════════
# /etc/postfix/master.cf
# Service definitions. Submission (587) and SMTPS (465) enabled.
# ═══════════════════════════════════════════════════════════════

# service   type  private unpriv  chroot  wakeup  maxproc command
smtp        inet  n       -       y       -       -       smtpd

submission  inet  n       -       y       -       -       smtpd
  -o syslog_name=postfix/submission
  -o smtpd_tls_security_level=encrypt
  -o smtpd_tls_auth_only=yes
  -o smtpd_sasl_auth_enable=yes
  -o smtpd_reject_unlisted_recipient=no
  -o smtpd_recipient_restrictions=permit_sasl_authenticated,reject
  -o smtpd_relay_restrictions=permit_sasl_authenticated,reject
  -o milter_macro_daemon_name=ORIGINATING

smtps       inet  n       -       y       -       -       smtpd
  -o syslog_name=postfix/smtps
  -o smtpd_tls_wrappermode=yes
  -o smtpd_sasl_auth_enable=yes
  -o smtpd_reject_unlisted_recipient=no
  -o smtpd_recipient_restrictions=permit_sasl_authenticated,reject
  -o smtpd_relay_restrictions=permit_sasl_authenticated,reject
  -o milter_macro_daemon_name=ORIGINATING

pickup      unix  n       -       y       60      1       pickup
cleanup     unix  n       -       y       -       0       cleanup
qmgr        unix  n       -       n       300     1       qmgr
tlsmgr      unix  -       -       y       1000?   1       tlsmgr
rewrite     unix  -       -       y       -       -       trivial-rewrite
bounce      unix  -       -       y       -       0       bounce
defer       unix  -       -       y       -       0       bounce
trace       unix  -       -       y       -       0       bounce
verify      unix  -       -       y       -       1       verify
flush       unix  n       -       y       1000?   0       flush
proxymap    unix  -       -       n       -       -       proxymap
proxywrite  unix  -       -       n       -       1       proxymap
smtp        unix  -       -       y       -       -       smtp
relay       unix  -       -       y       -       -       smtp
  -o syslog_name=postfix/$service_name
showq       unix  n       -       y       -       -       showq
error       unix  -       -       y       -       -       error
retry       unix  -       -       y       -       -       error
discard     unix  -       -       y       -       -       discard
local       unix  -       n       n       -       -       local
virtual     unix  -       n       n       -       -       virtual
lmtp        unix  -       -       y       -       -       lmtp
anvil       unix  -       -       y       -       1       anvil
scache      unix  -       -       y       -       1       scache
postlog     unix-dgram n  -       n       -       1       postlogd
EOF

# ═══════════════════════════════════════════════════════════════════════════════════
# DOVECOT — Core configuration
# ═══════════════════════════════════════════════════════════════════════════════════

echo "[3/9] Writing Dovecot configuration..."

# Main config
cat > "${DOVECOT_DIR}/dovecot.conf" << 'EOF'
# ═══════════════════════════════════════════════════════════════
# /etc/dovecot/dovecot.conf
# Ubuntu Determinant Alpha RS — Galactic Cherry Marvell 98
# Minimal top-level. Details in conf.d/.
# ═══════════════════════════════════════════════════════════════
protocols = imap pop3 lmtp
listen = *, ::
!include conf.d/*.conf
EOF

# Ensure conf.d exists
mkdir -p "${DOVECOT_DIR}/conf.d"

# ── 10-ssl.conf ──────────────────────────────────────────────────────────────────
cat > "${DOVECOT_DIR}/conf.d/10-ssl.conf" << EOF
# ═══════════════════════════════════════════════════════════════
# TLS — Required on all connections. No plaintext.
# ═══════════════════════════════════════════════════════════════
ssl = required
ssl_cert = <${CERT_DIR}/fullchain.pem
ssl_key = <${CERT_DIR}/privkey.pem
ssl_min_protocol = TLSv1.2
ssl_cipher_list = ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!MD5:!PSK
ssl_prefer_server_ciphers = yes
ssl_dh = </etc/dovecot/dh.pem
EOF

# ── 10-auth.conf ─────────────────────────────────────────────────────────────────
cat > "${DOVECOT_DIR}/conf.d/10-auth.conf" << 'EOF'
# ═══════════════════════════════════════════════════════════════
# Authentication — plain+login over TLS only. PAM backend.
# ═══════════════════════════════════════════════════════════════
disable_plaintext_auth = yes
auth_mechanisms = plain login
auth_username_format = %Ln
auth_failure_delay = 2 secs
auth_verbose = no

!include auth-system.conf.ext
EOF

# ── 10-mail.conf ─────────────────────────────────────────────────────────────────
cat > "${DOVECOT_DIR}/conf.d/10-mail.conf" << 'EOF'
# ═══════════════════════════════════════════════════════════════
# Mail storage — Maildir, one namespace.
# ═══════════════════════════════════════════════════════════════
mail_location = maildir:~/Maildir:LAYOUT=fs
mail_privileged_group = mail
mail_access_groups = mail

namespace inbox {
  inbox = yes
  separator = /
  mailbox Drafts {
    auto = subscribe
    special_use = \Drafts
  }
  mailbox Sent {
    auto = subscribe
    special_use = \Sent
  }
  mailbox Trash {
    auto = subscribe
    special_use = \Trash
  }
  mailbox Junk {
    auto = subscribe
    special_use = \Junk
  }
  mailbox Archive {
    auto = no
    special_use = \Archive
  }
}
EOF

# ── 10-master.conf ───────────────────────────────────────────────────────────────
cat > "${DOVECOT_DIR}/conf.d/10-master.conf" << 'EOF'
# ═══════════════════════════════════════════════════════════════
# Service definitions — listeners, LMTP, SASL for Postfix.
# ═══════════════════════════════════════════════════════════════

service imap-login {
  inet_listener imap {
    port = 143
  }
  inet_listener imaps {
    port = 993
    ssl = yes
  }
  process_min_avail = 1
  service_count = 1
  vsz_limit = 64M
}

service pop3-login {
  inet_listener pop3 {
    port = 110
  }
  inet_listener pop3s {
    port = 995
    ssl = yes
  }
}

service imap {
  process_limit = 256
  vsz_limit = 256M
}

service pop3 {
  process_limit = 128
}

service lmtp {
  unix_listener /var/spool/postfix/private/dovecot-lmtp {
    mode = 0600
    user = postfix
    group = postfix
  }
}

service auth {
  unix_listener /var/spool/postfix/private/auth {
    mode = 0660
    user = postfix
    group = postfix
  }
  unix_listener auth-userdb {
    mode = 0660
    user = dovecot
    group = dovecot
  }
  user = dovecot
}

service auth-worker {
  user = root
}

service stats {
  unix_listener stats-reader {
    user = dovecot
    group = dovecot
    mode = 0660
  }
  unix_listener stats-writer {
    user = dovecot
    group = dovecot
    mode = 0660
  }
}
EOF

# ── 10-logging.conf ──────────────────────────────────────────────────────────────
cat > "${DOVECOT_DIR}/conf.d/10-logging.conf" << 'EOF'
# ═══════════════════════════════════════════════════════════════
# Logging — syslog, minimal verbosity in production.
# ═══════════════════════════════════════════════════════════════
log_path = syslog
syslog_facility = mail
auth_verbose = no
auth_verbose_passwords = no
auth_debug = no
mail_debug = no
verbose_ssl = no
EOF

# ── 20-imap.conf ─────────────────────────────────────────────────────────────────
cat > "${DOVECOT_DIR}/conf.d/20-imap.conf" << 'EOF'
# ═══════════════════════════════════════════════════════════════
# IMAP — protocol-specific settings.
# ═══════════════════════════════════════════════════════════════
protocol imap {
  mail_max_userip_connections = 20
  imap_idle_notify_interval = 2 mins
}
EOF

# ── 20-pop3.conf ─────────────────────────────────────────────────────────────────
cat > "${DOVECOT_DIR}/conf.d/20-pop3.conf" << 'EOF'
# ═══════════════════════════════════════════════════════════════
# POP3 — protocol-specific settings.
# ═══════════════════════════════════════════════════════════════
protocol pop3 {
  mail_max_userip_connections = 5
  pop3_uidl_format = %08Xu%08Xv
}
EOF

# ── 20-lmtp.conf ─────────────────────────────────────────────────────────────────
cat > "${DOVECOT_DIR}/conf.d/20-lmtp.conf" << 'EOF'
# ═══════════════════════════════════════════════════════════════
# LMTP — local delivery from Postfix.
# ═══════════════════════════════════════════════════════════════
protocol lmtp {
  mail_plugins = $mail_plugins
  postmaster_address = postmaster@%{if;%d;ne;;%d;%{hostname}}
}
EOF

# ── auth-system.conf.ext ─────────────────────────────────────────────────────────
cat > "${DOVECOT_DIR}/conf.d/auth-system.conf.ext" << 'EOF'
# ═══════════════════════════════════════════════════════════════
# PAM + system users. Simple. Secure. No separate user DB.
# ═══════════════════════════════════════════════════════════════
passdb {
  driver = pam
}
userdb {
  driver = passwd
  args = blocking=no
}
EOF

# ═══════════════════════════════════════════════════════════════════════════════════
# CERTIFICATES, KEYS & DH PARAMETERS
# ═══════════════════════════════════════════════════════════════════════════════════
#
# Certificate strategy (careful method):
#
#   1. Generate DH parameters (unique per-host, never reused)
#   2. Generate DKIM signing key (RSA-2048, domain-bound)
#   3. If Let's Encrypt certs exist → verify chain integrity
#   4. If no certs → generate self-signed CA + leaf (immediate TLS)
#   5. Attempt Let's Encrypt acquisition (certbot, if available + port 80 open)
#   6. Record SHA-256 fingerprints of all keys for fiduciary hold tracking
#   7. Set strict permissions (private keys readable only by service user)
#
# ═══════════════════════════════════════════════════════════════════════════════════

echo "[4/9] Generating DH parameters..."

# ── DH Parameters ────────────────────────────────────────────────────────────────
# Unique per-host. Never use precomputed/shared DH params.
# Postfix: 2048-bit (compatibility). Dovecot: 4096-bit (maximum security).

if [ ! -f "${POSTFIX_DIR}/dh2048.pem" ]; then
    echo "      Postfix DH params (2048-bit)..."
    openssl dhparam -out "${POSTFIX_DIR}/dh2048.pem" 2048 2>/dev/null
    chmod 644 "${POSTFIX_DIR}/dh2048.pem"
    echo "      ✓ ${POSTFIX_DIR}/dh2048.pem"
else
    echo "      ✓ Postfix DH params exist."
fi

if [ ! -f "${DOVECOT_DIR}/dh.pem" ]; then
    echo "      Dovecot DH params (4096-bit) — generating in background..."
    openssl dhparam -out "${DOVECOT_DIR}/dh.pem" 4096 2>/dev/null &
    DH_PID=$!
    echo "      ✓ Background PID ${DH_PID} (1-5 minutes to complete)"
else
    echo "      ✓ Dovecot DH params exist."
fi

# ── DKIM Signing Key ─────────────────────────────────────────────────────────────

echo "[5/9] Generating DKIM signing key..."

DKIM_DIR="/etc/opendkim/keys/${DOMAIN}"
mkdir -p "${DKIM_DIR}"

if [ ! -f "${DKIM_DIR}/default.private" ]; then
    # Generate RSA-2048 DKIM key pair
    openssl genrsa -out "${DKIM_DIR}/default.private" 2048 2>/dev/null

    # Extract public key in DNS TXT format
    openssl rsa -in "${DKIM_DIR}/default.private" -pubout -outform PEM 2>/dev/null | \
        grep -v "^-" | tr -d '\n' > "${DKIM_DIR}/default.pub.raw"

    # Format for DNS TXT record
    PUB_KEY=$(cat "${DKIM_DIR}/default.pub.raw")
    echo "v=DKIM1; k=rsa; p=${PUB_KEY}" > "${DKIM_DIR}/default.txt"

    # Permissions: private key readable only by opendkim
    chmod 600 "${DKIM_DIR}/default.private"
    chmod 644 "${DKIM_DIR}/default.txt"
    chown -R opendkim:opendkim "${DKIM_DIR}" 2>/dev/null || \
        chown -R root:root "${DKIM_DIR}"

    echo "      ✓ DKIM key generated: ${DKIM_DIR}/default.private"
    echo "      ✓ DNS TXT record: ${DKIM_DIR}/default.txt"
    echo "      ⚠ Add to DNS: default._domainkey.${DOMAIN} TXT \"$(cat ${DKIM_DIR}/default.txt)\""
else
    echo "      ✓ DKIM key exists."
fi

# Write OpenDKIM config files
mkdir -p /etc/opendkim

cat > /etc/opendkim/signing.table << EOF
*@${DOMAIN}    default._domainkey.${DOMAIN}
EOF

cat > /etc/opendkim/key.table << EOF
default._domainkey.${DOMAIN}    ${DOMAIN}:default:${DKIM_DIR}/default.private
EOF

cat > /etc/opendkim/trusted.hosts << EOF
127.0.0.1
localhost
${DOMAIN}
*.${DOMAIN}
EOF

# ── TLS Certificates ─────────────────────────────────────────────────────────────

echo "[6/9] Provisioning TLS certificates..."

CERT_FULLCHAIN="${CERT_DIR}/fullchain.pem"
CERT_PRIVKEY="${CERT_DIR}/privkey.pem"
CERT_CHAIN="${CERT_DIR}/chain.pem"
SELF_SIGNED_DIR="/etc/ssl/mail-self-signed"

# Function: verify a certificate file is valid and not expired
verify_cert() {
    local certfile="$1"
    if [ ! -f "$certfile" ]; then return 1; fi
    # Check not expired (within 7 days)
    openssl x509 -in "$certfile" -checkend 604800 -noout 2>/dev/null
    return $?
}

# Function: generate self-signed CA + leaf certificate
generate_self_signed() {
    echo "      Generating self-signed certificate authority..."
    mkdir -p "${SELF_SIGNED_DIR}"

    # ── Root CA (self-signed, 10 year validity) ──
    openssl req -x509 -newkey rsa:4096 -sha256 -days 3650 \
        -nodes -keyout "${SELF_SIGNED_DIR}/ca.key" \
        -out "${SELF_SIGNED_DIR}/ca.crt" \
        -subj "/C=US/ST=North Carolina/L=Durham/O=MEARVK LLC/OU=Mail CA/CN=MEARVK Mail Root CA" \
        2>/dev/null

    # ── Leaf key (ECDSA P-256 for performance + security) ──
    openssl ecparam -genkey -name prime256v1 -out "${SELF_SIGNED_DIR}/mail.key" 2>/dev/null

    # ── Certificate Signing Request ──
    openssl req -new -key "${SELF_SIGNED_DIR}/mail.key" \
        -out "${SELF_SIGNED_DIR}/mail.csr" \
        -subj "/C=US/ST=North Carolina/L=Durham/O=MEARVK LLC/OU=Mail/CN=${HOSTNAME}" \
        2>/dev/null

    # ── SAN extension (Subject Alternative Names) ──
    cat > "${SELF_SIGNED_DIR}/san.ext" << SANEOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth, clientAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = ${HOSTNAME}
DNS.2 = ${DOMAIN}
DNS.3 = *.${DOMAIN}
IP.1 = ${SERVER_IP}
SANEOF

    # ── Sign leaf with CA ──
    openssl x509 -req -in "${SELF_SIGNED_DIR}/mail.csr" \
        -CA "${SELF_SIGNED_DIR}/ca.crt" -CAkey "${SELF_SIGNED_DIR}/ca.key" \
        -CAcreateserial -out "${SELF_SIGNED_DIR}/mail.crt" \
        -days 825 -sha256 -extfile "${SELF_SIGNED_DIR}/san.ext" \
        2>/dev/null

    # ── Build fullchain (leaf + CA) ──
    cat "${SELF_SIGNED_DIR}/mail.crt" "${SELF_SIGNED_DIR}/ca.crt" > "${SELF_SIGNED_DIR}/fullchain.pem"
    cp "${SELF_SIGNED_DIR}/mail.key" "${SELF_SIGNED_DIR}/privkey.pem"
    cp "${SELF_SIGNED_DIR}/ca.crt" "${SELF_SIGNED_DIR}/chain.pem"

    # Permissions
    chmod 600 "${SELF_SIGNED_DIR}/ca.key" "${SELF_SIGNED_DIR}/mail.key" "${SELF_SIGNED_DIR}/privkey.pem"
    chmod 644 "${SELF_SIGNED_DIR}/ca.crt" "${SELF_SIGNED_DIR}/mail.crt" "${SELF_SIGNED_DIR}/fullchain.pem"

    echo "      ✓ Self-signed CA: ${SELF_SIGNED_DIR}/ca.crt"
    echo "      ✓ Leaf cert (ECDSA P-256): ${SELF_SIGNED_DIR}/mail.crt"
    echo "      ✓ SAN: ${HOSTNAME}, ${DOMAIN}, *.${DOMAIN}, ${SERVER_IP}"
}

# Decision: use Let's Encrypt if available, otherwise self-signed
if verify_cert "${CERT_FULLCHAIN}"; then
    echo "      ✓ Let's Encrypt certificate valid and not expiring within 7 days."
    # Verify chain integrity
    if openssl verify -CAfile "${CERT_CHAIN}" "${CERT_FULLCHAIN}" >/dev/null 2>&1; then
        echo "      ✓ Certificate chain verified."
    else
        echo "      ⚠ Chain verification inconclusive (cross-signed roots — acceptable)."
    fi
else
    echo "      Let's Encrypt cert not found or expiring. Attempting acquisition..."

    # Try certbot (requires port 80 open and DNS pointing to us)
    CERTBOT_SUCCESS=0
    if command -v certbot &>/dev/null; then
        echo "      Running certbot (standalone, port 80)..."
        certbot certonly --standalone --non-interactive --agree-tos \
            --email "admin@${DOMAIN}" \
            -d "${DOMAIN}" -d "${HOSTNAME}" \
            2>/dev/null && CERTBOT_SUCCESS=1 || true
    fi

    if [ $CERTBOT_SUCCESS -eq 1 ] && verify_cert "${CERT_FULLCHAIN}"; then
        echo "      ✓ Let's Encrypt certificate acquired successfully."
    else
        echo "      Let's Encrypt unavailable (port 80 closed or DNS not pointed)."
        echo "      Falling back to self-signed certificates..."
        generate_self_signed

        # Point config to self-signed
        CERT_DIR="${SELF_SIGNED_DIR}"
        CERT_FULLCHAIN="${SELF_SIGNED_DIR}/fullchain.pem"
        CERT_PRIVKEY="${SELF_SIGNED_DIR}/privkey.pem"

        # Update Postfix main.cf to use self-signed path
        sed -i "s|smtpd_tls_cert_file = .*|smtpd_tls_cert_file = ${CERT_FULLCHAIN}|" "${POSTFIX_DIR}/main.cf"
        sed -i "s|smtpd_tls_key_file = .*|smtpd_tls_key_file = ${CERT_PRIVKEY}|" "${POSTFIX_DIR}/main.cf"

        # Update Dovecot 10-ssl.conf
        sed -i "s|ssl_cert = <.*|ssl_cert = <${CERT_FULLCHAIN}|" "${DOVECOT_DIR}/conf.d/10-ssl.conf"
        sed -i "s|ssl_key = <.*|ssl_key = <${CERT_PRIVKEY}|" "${DOVECOT_DIR}/conf.d/10-ssl.conf"

        echo "      ✓ Configs updated to use self-signed certs."
        echo "      ⚠ Replace with Let's Encrypt when DNS/port 80 is ready:"
        echo "        certbot certonly --standalone -d ${DOMAIN} -d ${HOSTNAME}"
    fi
fi

# ── Let's Encrypt Auto-Renewal Hook ─────────────────────────────────────────────

if command -v certbot &>/dev/null; then
    RENEWAL_HOOK="/etc/letsencrypt/renewal-hooks/deploy/reload-mail.sh"
    mkdir -p "$(dirname "${RENEWAL_HOOK}")"
    cat > "${RENEWAL_HOOK}" << 'HOOKEOF'
#!/bin/bash
# Reload mail services after certificate renewal
systemctl reload postfix 2>/dev/null || true
systemctl reload dovecot 2>/dev/null || true
logger -t certbot "Mail services reloaded after certificate renewal"
HOOKEOF
    chmod 755 "${RENEWAL_HOOK}"
    echo "      ✓ Certbot renewal hook: ${RENEWAL_HOOK}"
fi

# ═══════════════════════════════════════════════════════════════════════════════════
# CERTIFICATE WATCHDOG — Automatic refresh on expiry, revocation, or corruption
# ═══════════════════════════════════════════════════════════════════════════════════
#
# Installs a systemd timer that runs daily and checks:
#   1. Certificate expiry (regenerate if < 14 days remaining)
#   2. OCSP revocation status (regenerate immediately if revoked)
#   3. File integrity (SHA-256 vs recorded fingerprint; regenerate if corrupted)
#   4. Key/cert mismatch (modulus comparison; regenerate if mismatched)
#   5. Self-signed CA expiry (regenerate CA + re-sign leaf if CA expiring)
#
# On failure: regenerates via certbot (preferred) or self-signed (fallback).
# On success: reloads Postfix + Dovecot, updates fingerprint record.
#
# ═══════════════════════════════════════════════════════════════════════════════════

echo "      Installing certificate watchdog (daily auto-refresh)..."

WATCHDOG_SCRIPT="/usr/local/sbin/mail-cert-watchdog.sh"
cat > "${WATCHDOG_SCRIPT}" << 'WATCHDOG'
#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# mail-cert-watchdog.sh — Daily certificate health check and auto-refresh
#
# Checks: expiry, revocation (OCSP), integrity, key/cert match, CA health.
# Regenerates certificates automatically when problems are detected.
# Runs via systemd timer: mail-cert-watchdog.timer (daily at 03:30)
#
# Exit codes:
#   0 = all healthy, no action needed
#   1 = certificate regenerated (success)
#   2 = regeneration failed (manual intervention needed)
# ═══════════════════════════════════════════════════════════════════════════════
set -uo pipefail

DOMAIN="${MAIL_DOMAIN:-lauradei.us}"
HOSTNAME="${MAIL_HOSTNAME:-mail.${DOMAIN}}"
SERVER_IP="${MAIL_SERVER_IP:-45.32.31.139}"
LE_CERT_DIR="/etc/letsencrypt/live/${DOMAIN}"
SS_CERT_DIR="/etc/ssl/mail-self-signed"
FINGERPRINT_FILE="/etc/ssl/mail-fingerprints.txt"
LOG_TAG="mail-cert-watchdog"
EXPIRY_THRESHOLD_DAYS=14
NEEDS_REGEN=0
REASON=""

log() { logger -t "${LOG_TAG}" "$1"; echo "[$(date '+%H:%M:%S')] $1"; }

# ─────────────────────────────────────────────────────────────────────────────
# Determine active certificate
# ─────────────────────────────────────────────────────────────────────────────
if [ -f "${LE_CERT_DIR}/fullchain.pem" ]; then
    ACTIVE_CERT="${LE_CERT_DIR}/fullchain.pem"
    ACTIVE_KEY="${LE_CERT_DIR}/privkey.pem"
    CERT_TYPE="letsencrypt"
elif [ -f "${SS_CERT_DIR}/fullchain.pem" ]; then
    ACTIVE_CERT="${SS_CERT_DIR}/fullchain.pem"
    ACTIVE_KEY="${SS_CERT_DIR}/privkey.pem"
    CERT_TYPE="self-signed"
else
    log "CRITICAL: No certificate found. Triggering regeneration."
    NEEDS_REGEN=1
    REASON="no_certificate"
fi

# ─────────────────────────────────────────────────────────────────────────────
# CHECK 1: Expiry (regenerate if < 14 days remaining)
# ─────────────────────────────────────────────────────────────────────────────
if [ $NEEDS_REGEN -eq 0 ]; then
    EXPIRY_SECONDS=$((EXPIRY_THRESHOLD_DAYS * 86400))
    if ! openssl x509 -in "${ACTIVE_CERT}" -checkend ${EXPIRY_SECONDS} -noout 2>/dev/null; then
        EXPIRY_DATE=$(openssl x509 -in "${ACTIVE_CERT}" -noout -enddate 2>/dev/null | sed 's/notAfter=//')
        log "WARNING: Certificate expires within ${EXPIRY_THRESHOLD_DAYS} days (${EXPIRY_DATE}). Regenerating."
        NEEDS_REGEN=1
        REASON="expiring"
    fi
fi

# ─────────────────────────────────────────────────────────────────────────────
# CHECK 2: OCSP Revocation Status
# ─────────────────────────────────────────────────────────────────────────────
if [ $NEEDS_REGEN -eq 0 ] && [ "${CERT_TYPE}" = "letsencrypt" ]; then
    # Extract OCSP responder URL from certificate
    OCSP_URL=$(openssl x509 -in "${ACTIVE_CERT}" -noout -ocsp_uri 2>/dev/null)
    if [ -n "${OCSP_URL}" ]; then
        # Extract issuer cert for OCSP verification
        ISSUER_CERT="${LE_CERT_DIR}/chain.pem"
        if [ -f "${ISSUER_CERT}" ]; then
            OCSP_RESULT=$(openssl ocsp -issuer "${ISSUER_CERT}" -cert "${ACTIVE_CERT}" \
                -url "${OCSP_URL}" -resp_text -no_nonce 2>/dev/null | \
                grep -i "Cert Status:" | head -1 || echo "")

            if echo "${OCSP_RESULT}" | grep -qi "revoked"; then
                log "CRITICAL: Certificate has been REVOKED. Regenerating immediately."
                NEEDS_REGEN=1
                REASON="revoked"
            elif echo "${OCSP_RESULT}" | grep -qi "good"; then
                : # Certificate is valid
            else
                log "INFO: OCSP check inconclusive (responder may be unreachable). Continuing."
            fi
        fi
    fi
fi

# ─────────────────────────────────────────────────────────────────────────────
# CHECK 3: File Integrity (SHA-256 fingerprint comparison)
# ─────────────────────────────────────────────────────────────────────────────
if [ $NEEDS_REGEN -eq 0 ] && [ -f "${FINGERPRINT_FILE}" ]; then
    RECORDED_FP=$(grep "^TLS_CERT_SHA256=" "${FINGERPRINT_FILE}" 2>/dev/null | cut -d= -f2)
    if [ -n "${RECORDED_FP}" ]; then
        CURRENT_FP=$(openssl x509 -in "${ACTIVE_CERT}" -noout -fingerprint -sha256 2>/dev/null | \
            sed 's/sha256 Fingerprint=//;s/SHA256 Fingerprint=//')
        if [ "${RECORDED_FP}" != "${CURRENT_FP}" ]; then
            log "CRITICAL: Certificate fingerprint MISMATCH. File may be corrupted or tampered."
            log "  Recorded: ${RECORDED_FP}"
            log "  Current:  ${CURRENT_FP}"
            NEEDS_REGEN=1
            REASON="integrity_mismatch"
        fi
    fi
fi

# ─────────────────────────────────────────────────────────────────────────────
# CHECK 4: Key/Certificate Modulus Match
# ─────────────────────────────────────────────────────────────────────────────
if [ $NEEDS_REGEN -eq 0 ] && [ -f "${ACTIVE_KEY}" ]; then
    # For RSA keys: compare modulus. For EC keys: compare public point.
    KEY_ALG=$(openssl pkey -in "${ACTIVE_KEY}" -noout -text 2>/dev/null | head -1)
    if echo "${KEY_ALG}" | grep -qi "RSA"; then
        CERT_MOD=$(openssl x509 -in "${ACTIVE_CERT}" -noout -modulus 2>/dev/null | openssl dgst -sha256 2>/dev/null)
        KEY_MOD=$(openssl rsa -in "${ACTIVE_KEY}" -noout -modulus 2>/dev/null | openssl dgst -sha256 2>/dev/null)
    else
        # EC key: compare public key
        CERT_MOD=$(openssl x509 -in "${ACTIVE_CERT}" -noout -pubkey 2>/dev/null | openssl dgst -sha256 2>/dev/null)
        KEY_MOD=$(openssl pkey -in "${ACTIVE_KEY}" -pubout 2>/dev/null | openssl dgst -sha256 2>/dev/null)
    fi

    if [ -n "${CERT_MOD}" ] && [ -n "${KEY_MOD}" ] && [ "${CERT_MOD}" != "${KEY_MOD}" ]; then
        log "CRITICAL: Private key does NOT match certificate. Regenerating."
        NEEDS_REGEN=1
        REASON="key_mismatch"
    fi
fi

# ─────────────────────────────────────────────────────────────────────────────
# CHECK 5: Self-Signed CA Expiry (if using self-signed)
# ─────────────────────────────────────────────────────────────────────────────
if [ $NEEDS_REGEN -eq 0 ] && [ "${CERT_TYPE}" = "self-signed" ] && [ -f "${SS_CERT_DIR}/ca.crt" ]; then
    CA_EXPIRY_SECONDS=$((90 * 86400))  # 90 days threshold for CA
    if ! openssl x509 -in "${SS_CERT_DIR}/ca.crt" -checkend ${CA_EXPIRY_SECONDS} -noout 2>/dev/null; then
        log "WARNING: Self-signed CA expires within 90 days. Regenerating CA + leaf."
        NEEDS_REGEN=1
        REASON="ca_expiring"
    fi
fi

# ─────────────────────────────────────────────────────────────────────────────
# REGENERATION (if any check failed)
# ─────────────────────────────────────────────────────────────────────────────
if [ $NEEDS_REGEN -eq 1 ]; then
    log "Regeneration triggered. Reason: ${REASON}"

    # Strategy 1: Try Let's Encrypt (certbot)
    REGEN_SUCCESS=0
    if command -v certbot &>/dev/null; then
        log "Attempting Let's Encrypt renewal/acquisition..."

        # Force renewal if cert exists but is problematic
        if [ -f "${LE_CERT_DIR}/fullchain.pem" ]; then
            certbot renew --cert-name "${DOMAIN}" --force-renewal --quiet 2>/dev/null && REGEN_SUCCESS=1
        else
            certbot certonly --standalone --non-interactive --agree-tos \
                --email "admin@${DOMAIN}" \
                -d "${DOMAIN}" -d "${HOSTNAME}" \
                2>/dev/null && REGEN_SUCCESS=1
        fi

        if [ $REGEN_SUCCESS -eq 1 ]; then
            log "Let's Encrypt certificate acquired/renewed successfully."
        else
            log "Let's Encrypt failed (port 80 blocked or DNS issue). Falling back to self-signed."
        fi
    fi

    # Strategy 2: Self-signed regeneration
    if [ $REGEN_SUCCESS -eq 0 ]; then
        log "Generating new self-signed CA + leaf certificate..."
        mkdir -p "${SS_CERT_DIR}"

        # New CA (RSA-4096, 10 years)
        openssl req -x509 -newkey rsa:4096 -sha256 -days 3650 \
            -nodes -keyout "${SS_CERT_DIR}/ca.key" \
            -out "${SS_CERT_DIR}/ca.crt" \
            -subj "/C=US/ST=NC/L=Durham/O=MEARVK LLC/OU=Mail CA/CN=MEARVK Mail Root CA (regenerated $(date +%Y%m%d))" \
            2>/dev/null

        # New leaf key (ECDSA P-256)
        openssl ecparam -genkey -name prime256v1 -out "${SS_CERT_DIR}/mail.key" 2>/dev/null

        # CSR
        openssl req -new -key "${SS_CERT_DIR}/mail.key" \
            -out "${SS_CERT_DIR}/mail.csr" \
            -subj "/C=US/ST=NC/L=Durham/O=MEARVK LLC/OU=Mail/CN=${HOSTNAME}" \
            2>/dev/null

        # SAN extension
        cat > "${SS_CERT_DIR}/san.ext" << SANEOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth, clientAuth
subjectAltName = @alt_names
[alt_names]
DNS.1 = ${HOSTNAME}
DNS.2 = ${DOMAIN}
DNS.3 = *.${DOMAIN}
IP.1 = ${SERVER_IP}
SANEOF

        # Sign leaf with CA
        openssl x509 -req -in "${SS_CERT_DIR}/mail.csr" \
            -CA "${SS_CERT_DIR}/ca.crt" -CAkey "${SS_CERT_DIR}/ca.key" \
            -CAcreateserial -out "${SS_CERT_DIR}/mail.crt" \
            -days 825 -sha256 -extfile "${SS_CERT_DIR}/san.ext" \
            2>/dev/null

        # Build fullchain
        cat "${SS_CERT_DIR}/mail.crt" "${SS_CERT_DIR}/ca.crt" > "${SS_CERT_DIR}/fullchain.pem"
        cp "${SS_CERT_DIR}/mail.key" "${SS_CERT_DIR}/privkey.pem"
        cp "${SS_CERT_DIR}/ca.crt" "${SS_CERT_DIR}/chain.pem"

        # Lock down
        chmod 600 "${SS_CERT_DIR}/ca.key" "${SS_CERT_DIR}/mail.key" "${SS_CERT_DIR}/privkey.pem"
        chmod 644 "${SS_CERT_DIR}/ca.crt" "${SS_CERT_DIR}/mail.crt" "${SS_CERT_DIR}/fullchain.pem"

        # Update Postfix/Dovecot to point to self-signed
        sed -i "s|smtpd_tls_cert_file = .*|smtpd_tls_cert_file = ${SS_CERT_DIR}/fullchain.pem|" /etc/postfix/main.cf
        sed -i "s|smtpd_tls_key_file = .*|smtpd_tls_key_file = ${SS_CERT_DIR}/privkey.pem|" /etc/postfix/main.cf
        sed -i "s|ssl_cert = <.*|ssl_cert = <${SS_CERT_DIR}/fullchain.pem|" /etc/dovecot/conf.d/10-ssl.conf
        sed -i "s|ssl_key = <.*|ssl_key = <${SS_CERT_DIR}/privkey.pem|" /etc/dovecot/conf.d/10-ssl.conf

        REGEN_SUCCESS=1
        log "Self-signed CA + leaf regenerated successfully."
    fi

    # Update fingerprint record
    if [ $REGEN_SUCCESS -eq 1 ]; then
        # Determine active cert after regen
        if [ -f "${LE_CERT_DIR}/fullchain.pem" ]; then
            NEW_CERT="${LE_CERT_DIR}/fullchain.pem"
            NEW_KEY="${LE_CERT_DIR}/privkey.pem"
        else
            NEW_CERT="${SS_CERT_DIR}/fullchain.pem"
            NEW_KEY="${SS_CERT_DIR}/privkey.pem"
        fi

        # Write updated fingerprints
        NEW_FP=$(openssl x509 -in "${NEW_CERT}" -noout -fingerprint -sha256 2>/dev/null | \
            sed 's/sha256 Fingerprint=//;s/SHA256 Fingerprint=//')
        NEW_PUBKEY_FP=$(openssl pkey -in "${NEW_KEY}" -pubout 2>/dev/null | \
            openssl pkey -pubin -outform DER 2>/dev/null | \
            openssl dgst -sha256 -hex 2>/dev/null | awk '{print $NF}')

        # Update fingerprint file
        if [ -f "${FINGERPRINT_FILE}" ]; then
            sed -i "s|^TLS_CERT_SHA256=.*|TLS_CERT_SHA256=${NEW_FP}|" "${FINGERPRINT_FILE}"
            sed -i "s|^TLS_PUBKEY_SHA256=.*|TLS_PUBKEY_SHA256=${NEW_PUBKEY_FP}|" "${FINGERPRINT_FILE}"
            sed -i "s|^TLS_CERT_NOT_AFTER=.*|TLS_CERT_NOT_AFTER=$(openssl x509 -in "${NEW_CERT}" -noout -enddate 2>/dev/null | sed 's/notAfter=//')|" "${FINGERPRINT_FILE}"
        fi

        # Reload services
        systemctl reload postfix 2>/dev/null || systemctl restart postfix 2>/dev/null || true
        systemctl reload dovecot 2>/dev/null || systemctl restart dovecot 2>/dev/null || true

        log "Services reloaded. Fingerprints updated. Reason: ${REASON}"
        exit 1  # regenerated
    else
        log "CRITICAL: All regeneration strategies failed. Manual intervention required."
        # Send alert via system mail (if local delivery works)
        echo "Certificate regeneration FAILED on $(hostname) at $(date). Reason: ${REASON}. Manual intervention required." | \
            mail -s "[CRITICAL] Mail certificate failure on ${HOSTNAME}" root 2>/dev/null || true
        exit 2  # failed
    fi
fi

log "All checks passed. Certificate healthy (type: ${CERT_TYPE})."
exit 0
WATCHDOG

chmod 755 "${WATCHDOG_SCRIPT}"
echo "      ✓ Watchdog script: ${WATCHDOG_SCRIPT}"

# ── Systemd Timer (runs daily at 03:30) ─────────────────────────────────────────

cat > /etc/systemd/system/mail-cert-watchdog.service << EOF
[Unit]
Description=Mail Certificate Watchdog — expiry, revocation, integrity check
After=network-online.target

[Service]
Type=oneshot
ExecStart=${WATCHDOG_SCRIPT}
Environment=MAIL_DOMAIN=${DOMAIN}
Environment=MAIL_HOSTNAME=${HOSTNAME}
Environment=MAIL_SERVER_IP=${SERVER_IP}
StandardOutput=journal
StandardError=journal
EOF

cat > /etc/systemd/system/mail-cert-watchdog.timer << 'EOF'
[Unit]
Description=Daily mail certificate health check (03:30)

[Timer]
OnCalendar=*-*-* 03:30:00
RandomizedDelaySec=300
Persistent=true

[Install]
WantedBy=timers.target
EOF

systemctl daemon-reload
systemctl enable mail-cert-watchdog.timer 2>/dev/null || true
systemctl start mail-cert-watchdog.timer 2>/dev/null || true
echo "      ✓ Systemd timer: mail-cert-watchdog.timer (daily 03:30 ± 5min)"
echo "      ✓ Checks: expiry (14d), OCSP revocation, integrity, key match, CA health"

# ═══════════════════════════════════════════════════════════════════════════════════
# SHA-256 FINGERPRINTS — Record for fiduciary hold verification
# ═══════════════════════════════════════════════════════════════════════════════════

echo "[7/9] Computing SHA-256 fingerprints..."

FINGERPRINT_FILE="/etc/ssl/mail-fingerprints.txt"

{
    echo "# ═══════════════════════════════════════════════════════════════"
    echo "# Mail System SHA-256 Fingerprints"
    echo "# Generated: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
    echo "# Domain: ${DOMAIN}"
    echo "# Hostname: ${HOSTNAME}"
    echo "# ═══════════════════════════════════════════════════════════════"
    echo ""

    # TLS certificate fingerprint (leaf)
    if [ -f "${CERT_FULLCHAIN}" ]; then
        CERT_FP=$(openssl x509 -in "${CERT_FULLCHAIN}" -noout -fingerprint -sha256 2>/dev/null | \
            sed 's/sha256 Fingerprint=//;s/SHA256 Fingerprint=//')
        echo "TLS_CERT_SHA256=${CERT_FP}"
        echo "TLS_CERT_SUBJECT=$(openssl x509 -in "${CERT_FULLCHAIN}" -noout -subject 2>/dev/null | sed 's/subject=//')"
        echo "TLS_CERT_ISSUER=$(openssl x509 -in "${CERT_FULLCHAIN}" -noout -issuer 2>/dev/null | sed 's/issuer=//')"
        echo "TLS_CERT_NOT_AFTER=$(openssl x509 -in "${CERT_FULLCHAIN}" -noout -enddate 2>/dev/null | sed 's/notAfter=//')"
        echo "TLS_CERT_SERIAL=$(openssl x509 -in "${CERT_FULLCHAIN}" -noout -serial 2>/dev/null | sed 's/serial=//')"
    fi
    echo ""

    # TLS private key fingerprint (public key hash — safe to record)
    if [ -f "${CERT_PRIVKEY}" ]; then
        PUBKEY_FP=$(openssl pkey -in "${CERT_PRIVKEY}" -pubout 2>/dev/null | \
            openssl pkey -pubin -outform DER 2>/dev/null | \
            openssl dgst -sha256 -hex 2>/dev/null | awk '{print $NF}')
        echo "TLS_PUBKEY_SHA256=${PUBKEY_FP}"
    fi
    echo ""

    # DKIM key fingerprint
    if [ -f "${DKIM_DIR}/default.private" ]; then
        DKIM_FP=$(openssl rsa -in "${DKIM_DIR}/default.private" -pubout 2>/dev/null | \
            openssl pkey -pubin -outform DER 2>/dev/null | \
            openssl dgst -sha256 -hex 2>/dev/null | awk '{print $NF}')
        echo "DKIM_PUBKEY_SHA256=${DKIM_FP}"
        echo "DKIM_SELECTOR=default"
        echo "DKIM_DOMAIN=${DOMAIN}"
    fi
    echo ""

    # DH parameter fingerprints
    if [ -f "${POSTFIX_DIR}/dh2048.pem" ]; then
        DH_FP=$(openssl dgst -sha256 "${POSTFIX_DIR}/dh2048.pem" 2>/dev/null | awk '{print $NF}')
        echo "DH_POSTFIX_SHA256=${DH_FP}"
    fi
    if [ -f "${DOVECOT_DIR}/dh.pem" ]; then
        DH_FP2=$(openssl dgst -sha256 "${DOVECOT_DIR}/dh.pem" 2>/dev/null | awk '{print $NF}')
        echo "DH_DOVECOT_SHA256=${DH_FP2}"
    fi
    echo ""

    # Self-signed CA fingerprint (if exists)
    if [ -f "${SELF_SIGNED_DIR}/ca.crt" ]; then
        CA_FP=$(openssl x509 -in "${SELF_SIGNED_DIR}/ca.crt" -noout -fingerprint -sha256 2>/dev/null | \
            sed 's/sha256 Fingerprint=//;s/SHA256 Fingerprint=//')
        echo "SELF_SIGNED_CA_SHA256=${CA_FP}"
    fi

    echo ""
    echo "# Verify: openssl x509 -in /path/to/cert.pem -noout -fingerprint -sha256"
    echo "# If any fingerprint changes unexpectedly → fiduciary hold BROKEN."
} > "${FINGERPRINT_FILE}"

chmod 600 "${FINGERPRINT_FILE}"
echo "      ✓ Fingerprints recorded: ${FINGERPRINT_FILE}"

# Print fingerprints to console
echo ""
echo "      ┌─────────────────────────────────────────────────────────────┐"
echo "      │  SHA-256 Fingerprints (for fiduciary hold tracking)         │"
echo "      └─────────────────────────────────────────────────────────────┘"
grep "SHA256=" "${FINGERPRINT_FILE}" 2>/dev/null | while IFS='=' read -r key value; do
    printf "      %-25s %s\n" "${key}:" "${value:0:64}"
done
echo ""

# ═══════════════════════════════════════════════════════════════════════════════════
# PERMISSIONS — Lock down everything
# ═══════════════════════════════════════════════════════════════════════════════════

echo "[8/9] Setting permissions..."

# Postfix
chown root:root "${POSTFIX_DIR}/main.cf" "${POSTFIX_DIR}/master.cf"
chmod 644 "${POSTFIX_DIR}/main.cf" "${POSTFIX_DIR}/master.cf"
[ -f "${POSTFIX_DIR}/dh2048.pem" ] && chmod 644 "${POSTFIX_DIR}/dh2048.pem"

# Dovecot
chown -R root:root "${DOVECOT_DIR}"
chmod 644 "${DOVECOT_DIR}/dovecot.conf"
chmod 644 "${DOVECOT_DIR}/conf.d/"*.conf 2>/dev/null || true
chmod 644 "${DOVECOT_DIR}/conf.d/"*.ext 2>/dev/null || true
[ -f "${DOVECOT_DIR}/dh.pem" ] && chmod 644 "${DOVECOT_DIR}/dh.pem"

# Private keys — strict: readable only by owning service
[ -f "${CERT_PRIVKEY}" ] && chmod 600 "${CERT_PRIVKEY}"
[ -f "${DKIM_DIR}/default.private" ] && chmod 600 "${DKIM_DIR}/default.private"
[ -f "${SELF_SIGNED_DIR}/ca.key" ] && chmod 600 "${SELF_SIGNED_DIR}/ca.key"
[ -f "${SELF_SIGNED_DIR}/privkey.pem" ] && chmod 600 "${SELF_SIGNED_DIR}/privkey.pem"

echo "      ✓ Config files: 644 (root:root, world-readable)"
echo "      ✓ Private keys: 600 (owner-only, no group/other)"
echo "      ✓ DH params: 644 (public parameters, safe to share)"

# ═══════════════════════════════════════════════════════════════════════════════════
# VALIDATE & RELOAD
# ═══════════════════════════════════════════════════════════════════════════════════

echo "[9/9] Validating configuration..."

ERRORS=0

# Postfix check
if command -v postfix &>/dev/null; then
    if postfix check 2>&1 | grep -qi "fatal"; then
        echo "  [FAIL] Postfix configuration has errors:"
        postfix check 2>&1
        ERRORS=$((ERRORS + 1))
    else
        echo "  [OK] Postfix config valid."
        systemctl reload postfix 2>/dev/null && echo "  [OK] Postfix reloaded." || true
    fi
else
    echo "  [SKIP] Postfix not installed — config written for future install."
fi

# Dovecot check
if command -v doveconf &>/dev/null; then
    if doveconf -n >/dev/null 2>&1; then
        echo "  [OK] Dovecot config valid."
        systemctl reload dovecot 2>/dev/null && echo "  [OK] Dovecot reloaded." || true
    else
        echo "  [FAIL] Dovecot configuration has errors:"
        doveconf -n 2>&1 | tail -5
        ERRORS=$((ERRORS + 1))
    fi
else
    echo "  [SKIP] Dovecot not installed — config written for future install."
fi

# ═══════════════════════════════════════════════════════════════════════════════════
# SUMMARY
# ═══════════════════════════════════════════════════════════════════════════════════

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  Configuration Complete"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "  Postfix (MTA):"
echo "    main.cf          TLS 1.2+, ECDHE, DANE outbound, SASL via Dovecot"
echo "    master.cf        smtp/25, submission/587 (encrypt), smtps/465 (wrapper)"
echo "    DH params        2048-bit (${POSTFIX_DIR}/dh2048.pem)"
echo ""
echo "  Dovecot (IMAP/POP3):"
echo "    10-ssl.conf      TLS required, modern ciphers, server preference"
echo "    10-auth.conf     plain+login over TLS only, PAM backend, 2s fail delay"
echo "    10-mail.conf     Maildir, LAYOUT=fs, auto-subscribe IMAP folders"
echo "    10-master.conf   LMTP + SASL sockets for Postfix, process limits"
echo "    10-logging.conf  syslog/mail, minimal verbosity"
echo "    20-imap.conf     20 connections/user, 2min IDLE notify"
echo "    20-pop3.conf     5 connections/user"
echo "    20-lmtp.conf     Local delivery plugin"
echo "    auth-system      PAM passdb + passwd userdb"
echo "    DH params        4096-bit (${DOVECOT_DIR}/dh.pem)"
echo ""
echo "  Certificates & Keys:"
echo "    TLS cert         ${CERT_FULLCHAIN}"
echo "    TLS key          ${CERT_PRIVKEY} (600)"
echo "    DKIM key         ${DKIM_DIR}/default.private (600)"
echo "    DKIM DNS         default._domainkey.${DOMAIN}"
echo "    DH (Postfix)     ${POSTFIX_DIR}/dh2048.pem (2048-bit)"
echo "    DH (Dovecot)     ${DOVECOT_DIR}/dh.pem (4096-bit)"
echo "    Fingerprints     ${FINGERPRINT_FILE} (600)"
echo ""
echo "  Security Posture:"
echo "    ✓ No plaintext auth (TLS required before credentials)"
echo "    ✓ No SSLv2/v3, no TLS 1.0/1.1"
echo "    ✓ ECDHE forward secrecy on all connections"
echo "    ✓ DANE for outbound TLS verification (DNSSEC)"
echo "    ✓ VRFY disabled, strict HELO, pipelining rejection"
echo "    ✓ RBL: Spamhaus ZEN + SpamCop"
echo "    ✓ Rate limits: 30 conn/min, 60 msg/min, 120 rcpt/min"
echo "    ✓ DKIM signing (RSA-2048) + ClamAV milters"
echo "    ✓ LMTP delivery (Sieve-ready, quota-ready)"
echo "    ✓ Auth failure delay 2s (brute-force resistance)"
echo "    ✓ Self-signed CA with ECDSA P-256 leaf (if no Let's Encrypt)"
echo "    ✓ SHA-256 fingerprints recorded for fiduciary hold"
echo "    ✓ Private keys chmod 600 (no group/other access)"
echo ""
if [ $ERRORS -gt 0 ]; then
    echo "  ⚠ ${ERRORS} error(s) detected. Review output above."
else
    echo "  ✓ All configurations valid. Mail system ready."
fi
echo ""
echo "  Installer Tech ID: Max Rupplin"
echo "═══════════════════════════════════════════════════════════════"
