#!/bin/bash
# cron/install-cron.sh — Install reliable cron jobs for NWE services
# A Noble Mear — before Noble Ministries — a hare to include
#
# Usage: sudo bash cron/install-cron.sh

set -e

CRON_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$CRON_DIR")"
CRON_USER="${USER:-root}"
CRON_FILE="/etc/cron.d/nwe-mearvk"

echo "-- : [cron] Installing NWE cron schedule for ${CRON_USER}"
echo "-- : [cron] Project root: ${PROJECT_ROOT}"

sudo tee "$CRON_FILE" > /dev/null <<EOF
# NWE — NitroWebExpress™ Cron Schedule
# A Noble Mear — Reliable Services before Noble Ministries
# Installed: $(date -Iseconds)
SHELL=/bin/bash
PATH=/usr/local/bin:/usr/bin:/bin
PROJECT=${PROJECT_ROOT}

# AE6E66 — HOL/HOC crawl (monthly, 1st of month, 03:00)
0 3 1 * * ${CRON_USER} cd \${PROJECT} && java -cp modules/AE6E66/source source.AE6E66Main >> /var/log/nwe/ae6e66.log 2>&1

# Pull newer files from GitHub (daily, 04:00)
0 4 * * * ${CRON_USER} cd \${PROJECT} && bash scripts/github/pull-newer-only.sh >> /var/log/nwe/pull-newer.log 2>&1

# Signal Servers health check (every 15 min)
*/15 * * * * ${CRON_USER} cd \${PROJECT} && bash cron/signal-health.sh >> /var/log/nwe/signal-health.log 2>&1

# Postfix queue flush (every 30 min)
*/30 * * * * ${CRON_USER} /usr/sbin/postqueue -f >> /var/log/nwe/postfix-flush.log 2>&1

# MySQL backup (daily, 02:00)
0 2 * * * ${CRON_USER} cd \${PROJECT} && bash cron/mysql-backup.sh >> /var/log/nwe/mysql-backup.log 2>&1

# Strernary™ liveness (every 5 min)
*/5 * * * * ${CRON_USER} cd \${PROJECT} && bash cron/strernary-liveness.sh >> /var/log/nwe/strernary.log 2>&1

# Gray Port Registry lease expiry check (hourly)
0 * * * * ${CRON_USER} cd \${PROJECT} && bash cron/gray-lease-check.sh >> /var/log/nwe/gray-lease.log 2>&1

# Crypto binary integrity verification (every 48 hours — noble 2rways)
0 */48 * * * ${CRON_USER} cd \${PROJECT} && bash cron/crypto-verify.sh >> /var/log/nwe/crypto-verify.log 2>&1

# File integrity check against trusted GitHub commits (every 48 hours — Gifted Install Tech ID)
0 6 */2 * * ${CRON_USER} cd \${PROJECT} && bash cron/integrity-check.sh >> /var/log/nwe/integrity.log 2>&1
EOF

# Create log directory
sudo mkdir -p /var/log/nwe
sudo chown "${CRON_USER}:${CRON_USER}" /var/log/nwe

echo "-- : [cron] Installed to ${CRON_FILE}"
echo "-- : [cron] Logs: /var/log/nwe/"
echo "-- : [cron] Verify: crontab -l or cat ${CRON_FILE}"
