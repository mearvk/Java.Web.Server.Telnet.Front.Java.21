#!/bin/bash
# AE6E66 — Local Server Style Postfix Configuration
# For a machine with a static IP that sends mail directly (no relay, no cloud SMTP).
# Binds to all interfaces, accepts local submissions, delivers outbound via MX.
#
# Prerequisites: run install-postfix-dovecot.sh first.

set -e

DOMAIN="${1:-mearvk.us}"
HOSTNAME="mail.${DOMAIN}"
STATIC_IP="${2:-$(hostname -I | awk '{print $1}')}"

echo "-- : [AE6E66] Configuring local server style mail delivery"
echo "-- : [AE6E66] Domain: ${DOMAIN} | Hostname: ${HOSTNAME} | IP: ${STATIC_IP}"

# Core identity
sudo postconf -e "myhostname = ${HOSTNAME}"
sudo postconf -e "mydomain = ${DOMAIN}"
sudo postconf -e "myorigin = \$mydomain"

# Listen on loopback + static IP for local submission
sudo postconf -e "inet_interfaces = 127.0.0.1, ${STATIC_IP}"
sudo postconf -e "inet_protocols = ipv4"

# Local destinations
sudo postconf -e "mydestination = \$myhostname, localhost.\$mydomain, localhost, \$mydomain"

# Direct delivery — no relay host (own MX)
sudo postconf -e "relayhost ="
sudo postconf -e "mynetworks = 127.0.0.0/8, ${STATIC_IP}/32"

# TLS for outbound
sudo postconf -e "smtp_tls_security_level = may"
sudo postconf -e "smtp_tls_CAfile = /etc/ssl/certs/ca-certificates.crt"
sudo postconf -e "smtp_tls_loglevel = 1"

# Transport
sudo postconf -e "default_transport = smtp"
sudo postconf -e "relay_transport = smtp"

# Limits (avoid being flagged as spam)
sudo postconf -e "smtp_destination_rate_delay = 2s"
sudo postconf -e "smtp_destination_concurrency_limit = 2"
sudo postconf -e "default_destination_rate_delay = 1s"

# Header cleanup — remove local hostnames from Received headers
sudo postconf -e "header_checks = regexp:/etc/postfix/header_checks"
echo "/^Received:.*127\\.0\\.0\\.1/    IGNORE" | sudo tee /etc/postfix/header_checks > /dev/null

# SPF/DKIM note
echo "-- : [AE6E66] NOTE: For deliverability, configure DNS:"
echo "-- : [AE6E66]   TXT  ${DOMAIN}  \"v=spf1 ip4:${STATIC_IP} -all\""
echo "-- : [AE6E66]   Consider opendkim for DKIM signing."

sudo systemctl restart postfix

echo "-- : [AE6E66] Local server style configured."
echo "-- : [AE6E66] Bound to ${STATIC_IP}:25, direct MX delivery, rate-limited."
echo "-- : [AE6E66] Test: echo 'hello' | mail -s 'Local Server Test' recipient@example.com"
