#!/bin/bash
# Brarner.M.Alete™ — Install MySQL + Create Tables (macOS)
# Installs MySQL via Homebrew, creates BrarnerScience DB and all tables.
# Usage: bash install/macos/install-mysql-macos.sh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BMA_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
DB_PROPS="$BMA_ROOT/servlets/servlet/src/main/webapp/WEB-INF/db.properties"

echo "═══════════════════════════════════════════════════════════════"
echo " Brarner.M.Alete™ — MySQL Install (macOS)"
echo "═══════════════════════════════════════════════════════════════"

# Install Homebrew if missing
if ! command -v brew &>/dev/null; then
    echo "[*] Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Install MySQL
if ! command -v mysql &>/dev/null; then
    echo "[*] Installing MySQL via Homebrew..."
    brew install mysql
    echo "[OK] MySQL installed"
else
    echo "[*] MySQL already installed: $(mysql --version | head -1)"
fi

# Start MySQL
brew services start mysql 2>/dev/null || mysql.server start 2>/dev/null || true
echo "[OK] MySQL running"

# Read or prompt credentials
if [ -f "$DB_PROPS" ]; then
    DB_USER=$(grep '^db.user=' "$DB_PROPS" | cut -d= -f2-)
    DB_PASS=$(grep '^db.password=' "$DB_PROPS" | cut -d= -f2-)
    echo "[*] Using credentials from db.properties (user=$DB_USER)"
else
    read -rp "    MySQL admin username [root]: " DB_USER
    DB_USER="${DB_USER:-root}"
    read -rsp "    MySQL admin password: " DB_PASS
    echo ""
fi

MYSQL_CMD="mysql -u${DB_USER}"
[ -n "$DB_PASS" ] && MYSQL_CMD="$MYSQL_CMD -p${DB_PASS}"

# Create user and database
echo "[*] Creating database and user..."
$MYSQL_CMD -e "CREATE DATABASE IF NOT EXISTS BrarnerScience CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci; CREATE USER IF NOT EXISTS 'bma'@'localhost' IDENTIFIED BY 'bma123'; GRANT ALL PRIVILEGES ON BrarnerScience.* TO 'bma'@'localhost'; FLUSH PRIVILEGES;"

# Create tables
echo "[*] Creating tables..."
$MYSQL_CMD BrarnerScience < "$SCRIPT_DIR/create-tables.sql"

echo ""
echo "[OK] All tables created:"
$MYSQL_CMD -e "USE BrarnerScience; SHOW TABLES;"
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo " [✓] MySQL setup complete"
echo "     User: bma / bma123"
echo "     Database: BrarnerScience"
echo "     Next: bash install/populate-science-db.sh"
echo "═══════════════════════════════════════════════════════════════"
