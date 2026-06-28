#!/usr/bin/env bash
# Brarner.M.Alete™ — Create MySQL JDBC User
# Creates a dedicated 'bma' user for JSP/JDBC connections and updates db.properties
# Usage: sudo bash install/create-db-user.sh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BMA_ROOT="$(dirname "$SCRIPT_DIR")"
DB_PROPS="$BMA_ROOT/servlets/servlet/src/main/webapp/WEB-INF/db.properties"

echo "═══════════════════════════════════════════════════════════════"
echo " Brarner.M.Alete™ — Create MySQL JDBC User"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo " This creates a dedicated 'bma' MySQL user for JDBC connections."
echo " (root@localhost often uses unix_socket auth which blocks JDBC)"
echo ""

BMA_USER="bma"
BMA_PASS="bma_$(openssl rand -hex 8 2>/dev/null || echo 'Secure2026!')"
DB_NAME="BrarnerScience"

# Try connecting as root via socket (sudo mysql) first, then with password
echo "[*] Attempting to create user..."
if sudo mysql -e "SELECT 1" 2>/dev/null | grep -q 1; then
    echo "[*] Connected via sudo mysql (unix_socket)"
    sudo mysql <<SQL
CREATE DATABASE IF NOT EXISTS ${DB_NAME};
CREATE USER IF NOT EXISTS '${BMA_USER}'@'localhost' IDENTIFIED BY '${BMA_PASS}';
ALTER USER '${BMA_USER}'@'localhost' IDENTIFIED BY '${BMA_PASS}';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${BMA_USER}'@'localhost';
FLUSH PRIVILEGES;
SQL
elif mysql -u root -e "SELECT 1" 2>/dev/null | grep -q 1; then
    echo "[*] Connected as root (no password)"
    mysql -u root <<SQL
CREATE DATABASE IF NOT EXISTS ${DB_NAME};
CREATE USER IF NOT EXISTS '${BMA_USER}'@'localhost' IDENTIFIED BY '${BMA_PASS}';
ALTER USER '${BMA_USER}'@'localhost' IDENTIFIED BY '${BMA_PASS}';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${BMA_USER}'@'localhost';
FLUSH PRIVILEGES;
SQL
else
    echo "[*] Need root MySQL password to create JDBC user."
    read -rsp "    MySQL root password: " ROOT_PASS
    echo ""
    mysql -u root -p"$ROOT_PASS" <<SQL
CREATE DATABASE IF NOT EXISTS ${DB_NAME};
CREATE USER IF NOT EXISTS '${BMA_USER}'@'localhost' IDENTIFIED BY '${BMA_PASS}';
ALTER USER '${BMA_USER}'@'localhost' IDENTIFIED BY '${BMA_PASS}';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${BMA_USER}'@'localhost';
FLUSH PRIVILEGES;
SQL
fi

# Verify the new user can connect via TCP (JDBC style)
echo "[*] Verifying JDBC-style connection..."
if mysql -u "$BMA_USER" -p"$BMA_PASS" -h 127.0.0.1 "$DB_NAME" -e "SELECT 1" 2>/dev/null | grep -q 1; then
    echo "[OK] User '$BMA_USER' can connect via TCP (JDBC will work)"
else
    echo "[FAIL] TCP connection failed. Check MySQL bind-address."
    echo "       Ensure /etc/mysql/mysql.conf.d/mysqld.cnf has: bind-address = 127.0.0.1"
    exit 1
fi

# Write db.properties
mkdir -p "$(dirname "$DB_PROPS")"
cat > "$DB_PROPS" <<EOF
# BMA Database Configuration — written by create-db-user.sh
# JDBC user (dedicated, not root) for JSP server-side connections
db.driver=com.mysql.cj.jdbc.Driver
db.url=jdbc:mysql://127.0.0.1:3306/${DB_NAME}
db.user=${BMA_USER}
db.password=${BMA_PASS}
EOF
chmod 600 "$DB_PROPS"

echo ""
echo "[✓] db.properties updated:"
echo "    File: $DB_PROPS"
echo "    User: $BMA_USER"
echo "    Host: 127.0.0.1 (TCP, not socket)"
echo "    DB:   $DB_NAME"
echo ""
echo "    JSP pages will now connect as '$BMA_USER' over TCP."
echo "    Run: bash install/check-db.sh to verify."
echo "═══════════════════════════════════════════════════════════════"
