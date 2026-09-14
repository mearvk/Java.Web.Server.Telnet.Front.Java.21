#!/usr/bin/env bash
# Brarner.M.Alete™ — Set Database Credentials
# Prompts for MySQL password, verifies it works, and writes to db.properties
# Usage: bash install/set-db-credentials.sh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BMA_ROOT="$(dirname "$SCRIPT_DIR")"
DB_PROPS="$BMA_ROOT/servlets/servlet/src/main/webapp/WEB-INF/db.properties"

echo "═══════════════════════════════════════════════════════════════"
echo " Brarner.M.Alete™ — Set Database Credentials"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo " Target: $DB_PROPS"
echo ""

# Prompt for credentials
read -p " MySQL host [localhost]: " DB_HOST
DB_HOST="${DB_HOST:-localhost}"

read -p " MySQL port [3306]: " DB_PORT
DB_PORT="${DB_PORT:-3306}"

read -p " MySQL user [root]: " DB_USER
DB_USER="${DB_USER:-root}"

read -sp " MySQL password: " DB_PASS
echo ""

read -p " Database name [BrarnerScience]: " DB_NAME
DB_NAME="${DB_NAME:-BrarnerScience}"

# Test connection
echo ""
echo "[*] Testing connection..."
if mysql -u"$DB_USER" -p"$DB_PASS" -h"$DB_HOST" -P"$DB_PORT" -e "SELECT 1" 2>/dev/null | grep -q 1; then
    echo "[OK] Connection successful"
else
    echo "[FAIL] Cannot connect with those credentials."
    echo "       Tried: mysql -u$DB_USER -h$DB_HOST -P$DB_PORT"
    exit 1
fi

# Ensure database exists
mysql -u"$DB_USER" -p"$DB_PASS" -h"$DB_HOST" -P"$DB_PORT" -e "CREATE DATABASE IF NOT EXISTS $DB_NAME;" 2>/dev/null
echo "[OK] Database '$DB_NAME' ready"

# Write db.properties
mkdir -p "$(dirname "$DB_PROPS")"
cat > "$DB_PROPS" <<EOF
# BMA Database Configuration — written by install/set-db-credentials.sh
# Read by JSP pages at runtime for server-side JDBC connections
db.driver=com.mysql.cj.jdbc.Driver
db.url=jdbc:mysql://${DB_HOST}:${DB_PORT}/${DB_NAME}
db.user=${DB_USER}
db.password=${DB_PASS}
EOF

chmod 600 "$DB_PROPS"

echo ""
echo "[OK] Credentials written to:"
echo "     $DB_PROPS"
echo ""
echo " To verify: bash install/check-db.sh"
echo "═══════════════════════════════════════════════════════════════"
