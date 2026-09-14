#!/bin/bash
# cron/save-noble-state.sh — Shutdown concern: save brothers' state before disconcern
# Hooked into JVM shutdown / systemd ExecStop
# Saves last-run timestamps, job status, and registry state to .noble-state

set -e

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
STATE_FILE="${PROJECT_ROOT}/cron/.noble-state"

echo "-- : [noble-registry] Shutdown concern — saving brothers' state..."

cat > "$STATE_FILE" <<EOF
# Noble Registry State — saved at shutdown
# Before we disconcern our noble brothers, we save their state
timestamp=$(date -Iseconds)
reset_interval_hours=48

[jobs]
AE6E66-Crawl.last=$(stat -c %Y "${PROJECT_ROOT}/modules/AE6E66/configuration/.last-crawl" 2>/dev/null || echo "never")
GitHubPullNewer.last=$(date -r /var/log/nwe/pull-newer.log +%s 2>/dev/null || echo "never")
SignalHealth.last=$(date -r /var/log/nwe/signal-health.log +%s 2>/dev/null || echo "never")
MySQLBackup.last=$(date -r /var/log/nwe/mysql-backup.log +%s 2>/dev/null || echo "never")
StrernaryLiveness.last=$(date -r /var/log/nwe/strernary.log +%s 2>/dev/null || echo "never")
GrayLeaseCheck.last=$(date -r /var/log/nwe/gray-lease.log +%s 2>/dev/null || echo "never")

[ports]
49201=$(ss -tln | grep -c :49201 || echo 0)
49202=$(ss -tln | grep -c :49202 || echo 0)
49203=$(ss -tln | grep -c :49203 || echo 0)
49204=$(ss -tln | grep -c :49204 || echo 0)
20000=$(ss -tln | grep -c :20000 || echo 0)
9999=$(ss -tln | grep -c :9999 || echo 0)
10085=$(ss -tln | grep -c :10085 || echo 0)
5000=$(ss -tln | grep -c :5000 || echo 0)

[postfix]
queue_count=$(postqueue -p 2>/dev/null | tail -1 | grep -oP '\d+' || echo 0)
EOF

echo "-- : [noble-registry] State saved to ${STATE_FILE}"
