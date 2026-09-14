#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# NitroWebExpress™ — Shutdown MySQL
# Stops the MySQL service gracefully.
# Usage: bash scripts/shutdown-mysql.sh
# ═══════════════════════════════════════════════════════════════════════════════
set -uo pipefail

source "$( cd "$(dirname "$0")" && pwd )/detect-mysql.sh" || true

echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║  NitroWebExpress™ — Stop MySQL                                            ║"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"
echo ""

# Check if MySQL is running
if ! mysqladmin ping -h "$MYSQL_HOST" -P "$MYSQL_PORT" --silent 2>/dev/null; then
    echo "  [✓] MySQL is not running (already stopped)"
    exit 0
fi

echo "  [*] Stopping MySQL service..."

if systemctl is-active --quiet mysql 2>/dev/null; then
    sudo systemctl stop mysql 2>/dev/null && echo "  [✓] MySQL stopped via systemctl" || true
elif sudo mysqladmin shutdown 2>/dev/null; then
    sleep 2
    echo "  [✓] MySQL shut down gracefully"
else
    echo "  [!] Could not stop MySQL via systemctl or mysqladmin"
    echo "      Attempting pkill..."
    sudo pkill -f mysqld 2>/dev/null || true
    sleep 2
fi

# Verify it's stopped
if mysqladmin ping -h "$MYSQL_HOST" -P "$MYSQL_PORT" --silent 2>/dev/null; then
    echo "  [!] MySQL still running, attempting force stop..."
    sudo pkill -9 -f mysqld 2>/dev/null || true
    sleep 2
fi

echo ""
echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║  MySQL stopped.                                                            ║"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"

