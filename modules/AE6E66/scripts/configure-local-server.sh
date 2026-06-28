#!/bin/bash
# AE6E66 — Local Server Style Postfix Configuration
# For a machine with a static IP that sends mail directly (no relay, no cloud SMTP).
# Binds to all interfaces, accepts local submissions, delivers outbound via MX.
#
# Prerequisites: run install-postfix-dovecot.sh first.
set -euo pipefail

DOMAIN="${1:-lauradei.us}"
HOSTNAME="mail.${DOMAIN}"
STATIC_IP="${2:-$(hostname -I | awk '{print $1}')}"

# Validate IP format
if ! [[ "${STATIC_IP}" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "ERROR: Invalid IP address: ${STATIC_IP}"
    exit 1
fi

echo "-- : [AE6E66] Configuring local server style mail delivery"
echo "-- : [AE6E66] Domain: ${DOMAIN} | Hostname: ${HOSTNAME} | IP: ${STATIC_IP}"

# Core identity
sudo postconf -e "myhostname = ${HOSTNAME}"
sudo postconf -e "mydomain = ${DOMAIN}"
sudo postconf -e "myorigin = \$mydomain"

# Listen on loopback + static IP for local submission only
sudo postconf -e "inet_interfaces = 127.0.0.1, ${STATIC_IP}"
sudo postconf -e "inet_protocols = ipv4"

# Local destinations
sudo postconf -e "mydestination = \$myhostname, localhost.\$mydomain, localhost, \$mydomain"

# Direct delivery — no relay host (own MX)
sudo postconf -e "relayhost ="
sudo postconf -e "mynetworks = 127.0.0.0/8, ${STATIC_IP}/32"

# Relay restrictions — prevent open relay
sudo postconf -e "smtpd_relay_restrictions = permit_mynetworks, reject_unauth_destination"
sudo postconf -e "smtpd_recipient_restrictions = permit_mynetworks, reject_unauth_destination"
sudo postconf -e "smtpd_helo_required = yes"
sudo postconf -e "smtpd_helo_restrictions = reject_invalid_helo_hostname"

# TLS for outbound — enforce minimum TLS 1.2
sudo postconf -e "smtp_tls_security_level = encrypt"
sudo postconf -e "smtp_tls_CAfile = /etc/ssl/certs/ca-certificates.crt"
sudo postconf -e "smtp_tls_mandatory_protocols = >=TLSv1.2"
sudo postconf -e "smtp_tls_mandatory_ciphers = high"
sudo postconf -e "smtp_tls_loglevel = 1"

# Transport
sudo postconf -e "default_transport = smtp"
sudo postconf -e "relay_transport = smtp"

# Rate limits (polite sender — avoid spam flags)
sudo postconf -e "smtp_destination_rate_delay = 2s"
sudo postconf -e "smtp_destination_concurrency_limit = 2"
sudo postconf -e "default_destination_rate_delay = 1s"

# Header cleanup — remove internal hostnames from Received headers
sudo postconf -e "header_checks = regexp:/etc/postfix/header_checks"
cat <<'HEADER' | sudo tee /etc/postfix/header_checks > /dev/null
/^Received:.*127\.0\.0\.1/    IGNORE
/^Received:.*localhost/        IGNORE
HEADER
sudo chmod 644 /etc/postfix/header_checks

# Restrict config file permissions
sudo chmod 644 /etc/postfix/main.cf

echo "-- : [AE6E66] DNS Records Required:"
echo "-- : [AE6E66]   A     mail.${DOMAIN} -> ${STATIC_IP}"
echo "-- : [AE6E66]   MX    ${DOMAIN} -> mail.${DOMAIN} (priority 10)"
echo "-- : [AE6E66]   TXT   ${DOMAIN}  \"v=spf1 ip4:${STATIC_IP} -all\""
echo "-- : [AE6E66]   Consider opendkim for DKIM signing (see setup-dkim-lauradei.sh)"

sudo systemctl restart postfix

echo "-- : [AE6E66] Local server style configured."
echo "-- : [AE6E66] Bound to ${STATIC_IP}:25, direct MX delivery, rate-limited, TLS enforced."
