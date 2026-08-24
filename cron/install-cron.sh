#!/bin/bash
# cron/install-cron.sh — Install reliable cron jobs for NWE services
# Usage: sudo bash cron/install-cron.sh

set -euo pipefail

CRON_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$CRON_DIR/.." && pwd)"
CRON_USER="${CRON_USER:-${SUDO_USER:-$(id -un)}}"
CRON_FILE="/etc/cron.d/nwe-mearvk"
LOG_DIR="/var/log/nwe"

if [[ ! -d "$PROJECT_ROOT" || ! -d "$PROJECT_ROOT/scripts" ]]; then
    echo "[FAIL] Invalid project root: $PROJECT_ROOT" >&2
    exit 1
fi

if ! id "$CRON_USER" >/dev/null 2>&1; then
    echo "[FAIL] Cron user does not exist: $CRON_USER" >&2
    exit 1
fi

if [[ "$(id -u)" -ne 0 ]]; then
    echo "[FAIL] Run as root (for example: sudo bash cron/install-cron.sh)." >&2
    exit 1
fi

echo "[cron] Installing NWE schedule for ${CRON_USER}"
echo "[cron] Project root: ${PROJECT_ROOT}"

mkdir -p "$LOG_DIR"
chown "$CRON_USER:$CRON_USER" "$LOG_DIR"

cat > "$CRON_FILE" <<EOF
# NWE — NitroWebExpress cron schedule
# Installed: $(date -Iseconds)
SHELL=/bin/bash
PATH=/usr/local/bin:/usr/bin:/bin
PROJECT=${PROJECT_ROOT}

0 3 1 * * ${CRON_USER} cd "\${PROJECT}" && java -cp modules/AE6E66/source source.AE6E66Main >> /var/log/nwe/ae6e66.log 2>&1
0 4 * * * ${CRON_USER} cd "\${PROJECT}" && bash scripts/github/pull-newer-only.sh >> /var/log/nwe/pull-newer.log 2>&1
*/15 * * * * ${CRON_USER} cd "\${PROJECT}" && bash cron/signal-health.sh >> /var/log/nwe/signal-health.log 2>&1
*/30 * * * * ${CRON_USER} /usr/sbin/postqueue -f >> /var/log/nwe/postfix-flush.log 2>&1
0 2 * * * ${CRON_USER} cd "\${PROJECT}" && bash cron/mysql-backup.sh >> /var/log/nwe/mysql-backup.log 2>&1
*/5 * * * * ${CRON_USER} cd "\${PROJECT}" && bash cron/strernary-liveness.sh >> /var/log/nwe/strernary.log 2>&1
0 * * * * ${CRON_USER} cd "\${PROJECT}" && bash cron/gray-lease-check.sh >> /var/log/nwe/gray-lease.log 2>&1
0 */48 * * * ${CRON_USER} cd "\${PROJECT}" && bash cron/crypto-verify.sh >> /var/log/nwe/crypto-verify.log 2>&1
0 6 */2 * * ${CRON_USER} cd "\${PROJECT}" && bash cron/integrity-check.sh >> /var/log/nwe/integrity.log 2>&1
EOF

chmod 0644 "$CRON_FILE"

echo "[cron] Installed to ${CRON_FILE}"
echo "[cron] Logs: ${LOG_DIR}/"
echo "[cron] Verify: cat ${CRON_FILE}"
