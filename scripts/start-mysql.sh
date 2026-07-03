#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# NitroWebExpress™ — Start MySQL
# Starts the MySQL service and verifies connectivity.
# Usage: bash scripts/start-mysql.sh
# ═══════════════════════════════════════════════════════════════════════════════
set -uo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$PROJECT_ROOT/scripts/detect-mysql.sh"

echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║  NitroWebExpress™ — Start MySQL                                           ║"
echo "║  Datadir: $MYSQL_DATADIR                                                  ║"
echo "║  Block Storage: $MYSQL_ON_BLOCK                                           ║"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"
echo ""

# Check if MySQL is running
if mysqladmin ping -h "$MYSQL_HOST" -P "$MYSQL_PORT" --silent 2>/dev/null; then
    echo "  [✓] MySQL already running on $MYSQL_HOST:$MYSQL_PORT"
    exit 0
fi

echo "  [*] MySQL is not running, attempting to start..."
echo ""

# Try to start MySQL service
if systemctl is-active --quiet mysql 2>/dev/null; then
    echo "  [✓] MySQL service is already active"
elif sudo systemctl start mysql 2>/dev/null; then
    echo "  [*] Started MySQL service via systemctl..."
    sleep 2
else
    echo "  [!] Could not start MySQL service via systemctl"
    echo "      Trying: mysqld_safe in background..."
    sudo mysqld_safe &
    sleep 3
fi

# Wait for MySQL to be ready (up to 30 seconds)
echo "  [*] Waiting for MySQL to respond..."
for i in $(seq 1 30); do
    if mysqladmin ping -h "$MYSQL_HOST" -P "$MYSQL_PORT" --silent 2>/dev/null; then
        echo "  [✓] MySQL ready (took ${i}s)"
        echo ""
        echo "╔═══════════════════════════════════════════════════════════════════════════╗"
        echo "║  MySQL is ready!                                                          ║"
        echo "║  Host: $MYSQL_HOST:$MYSQL_PORT                                            ║"
        echo "║  Datadir: $MYSQL_DATADIR                                                  ║"
        echo "╚═══════════════════════════════════════════════════════════════════════════╝"
        exit 0
    fi
    sleep 1
done

echo "  [FAIL] MySQL did not become ready within 30 seconds"
exit 1

