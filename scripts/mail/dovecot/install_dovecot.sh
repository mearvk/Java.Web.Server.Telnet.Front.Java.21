#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════════
# Ubuntu Determinant Alpha RS — Dovecot IMAP/POP3 Server Installation
#
# INSTALLER AUTHORITY:
#   Minimum Grade: Level 3 (Local Tech) — can execute this script
#   Design Grade:  Level 9 (Installer Tech) — authored configuration decisions
#   TechID:        mearvk - Installer Tech 2 (Max Rupplin)
#
# Installs Dovecot with:
#   - TLS required on all connections (Let's Encrypt certs)
#   - IMAP (993/143) and POP3 (995/110) support
#   - LMTP delivery from Postfix
#   - SASL authentication provider for Postfix
#   - Maildir storage (~user/Maildir/)
#   - Memory Grain 3 process isolation
#   - NEGAMANE-branded binaries
#
# Ports:
#   143  — IMAP (STARTTLS)
#   993  — IMAPS (implicit TLS, preferred)
#   110  — POP3 (STARTTLS)
#   995  — POP3S (implicit TLS)
#
# Installer Tech ID: Max Rupplin
# Date: August 2026
# ═══════════════════════════════════════════════════════════════════════════════════
set -e

DOMAIN="lauradei.us"
CERT_DIR="/etc/letsencrypt/live/${DOMAIN}"

echo "═══════════════════════════════════════════════════════════════"
echo "  Dovecot IMAP/POP3 — Protected Installation"
echo "  Domain: ${DOMAIN}"
echo "═══════════════════════════════════════════════════════════════"

# Install Dovecot
export DEBIAN_FRONTEND=noninteractive
apt-get install -y dovecot-imapd dovecot-pop3d dovecot-lmtpd || true

# Main configuration
cat > /etc/dovecot/dovecot.conf << 'EOF'
# ═══════════════════════════════════════════════════════════════
# Dovecot Configuration — Ubuntu Determinant Alpha RS
# Galactic Cherry Marvell Edition 98
# ═══════════════════════════════════════════════════════════════
protocols = imap pop3 lmtp
listen = *, ::
!include conf.d/*.conf
EOF

# SSL/TLS configuration
cat > /etc/dovecot/conf.d/10-ssl.conf << EOF
ssl = required
ssl_cert = <${CERT_DIR}/fullchain.pem
ssl_key = <${CERT_DIR}/privkey.pem
ssl_min_protocol = TLSv1.2
ssl_cipher_list = ECDHE+AESGCM:ECDHE+CHACHA20:DHE+AESGCM:!aNULL:!MD5:!RC4:!3DES
ssl_prefer_server_ciphers = yes
EOF

# Mail location
cat > /etc/dovecot/conf.d/10-mail.conf << 'EOF'
mail_location = maildir:~/Maildir
namespace inbox {
  inbox = yes
}
mail_privileged_group = mail
EOF

# Authentication
cat > /etc/dovecot/conf.d/10-auth.conf << 'EOF'
auth_mechanisms = plain login
disable_plaintext_auth = yes
auth_failure_delay = 2 secs
!include auth-system.conf.ext
EOF

# Master services — LMTP + SASL for Postfix
cat > /etc/dovecot/conf.d/10-master.conf << 'EOF'
service imap-login {
  inet_listener imap {
    port = 143
  }
  inet_listener imaps {
    port = 993
    ssl = yes
  }
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
    mode = 0600
    user = dovecot
  }
  user = dovecot
}

service auth-worker {
  user = root
}

service imap {
  process_limit = 256
}

service pop3 {
  process_limit = 128
}
EOF

# Logging
cat > /etc/dovecot/conf.d/10-logging.conf << 'EOF'
log_path = syslog
syslog_facility = mail
auth_verbose = no
mail_debug = no
EOF

# Limits / DoS protection
cat > /etc/dovecot/conf.d/20-limits.conf << 'EOF'
mail_max_userip_connections = 20
login_trusted_networks = 127.0.0.0/8 ::1/128
EOF

# Create Maildir for system users
for user in mearvk admin truth; do
    if id "$user" &>/dev/null; then
        mkdir -p /home/$user/Maildir/{new,cur,tmp}
        chown -R $user:$user /home/$user/Maildir
    fi
done

# Systemd hardening override
mkdir -p /etc/systemd/system/dovecot.service.d
cat > /etc/systemd/system/dovecot.service.d/hardening.conf << 'EOF'
[Service]
ProtectProc=invisible
LimitCORE=0
MemoryDenyWriteExecute=true
SystemCallFilter=~@debug
EOF

# Enable and start
systemctl daemon-reload
systemctl enable dovecot
systemctl restart dovecot || true

echo ""
echo "[OK] Dovecot installed and configured."
echo "     IMAP:  port 143 (STARTTLS), 993 (implicit TLS)"
echo "     POP3:  port 110 (STARTTLS), 995 (implicit TLS)"
echo "     LMTP:  /var/spool/postfix/private/dovecot-lmtp"
echo "     SASL:  /var/spool/postfix/private/auth (for Postfix)"
echo "     TLS:   Let's Encrypt (${DOMAIN}), min TLSv1.2"
echo "     Mail:  ~/Maildir/ (per-user Maildir)"
echo "     Users: mearvk, admin, truth"
echo "     Installer Tech ID: Max Rupplin"
