#!/usr/bin/env bash
# MySQL.setup.sh — download, install, and configure MySQL for NitroWebExpress
#
# What this script does:
#   1. Verifies sudo access upfront (fails fast if not available)
#   2. Installs mysql-server via apt if not already installed
#   3. Ensures the MySQL service is enabled and running
#   4. Creates the N21 database and application user (mearvk)
#   5. Runs N21.SQL.Table.Builder.sh to create all application tables
#   6. Writes authentication/mysql.auth.xml if it does not already exist
#
# Usage:
#   bash bash/MySQL.setup.sh
#   bash bash/MySQL.setup.sh --password <app-user-password>
#
# The default app-user password matches authentication/mysql.auth.xml.
# Override with --password if you want a different credential.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_USER="mearvk"
APP_PASS='$$Ironman1'      # default — matches authentication/mysql.auth.xml
DB_NAME="N21"
AUTH_FILE="$ROOT/authentication/mysql.auth.xml"

# ── Parse args ────────────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
    case "$1" in
        --password) APP_PASS="$2"; shift 2 ;;
        *) echo "Unknown argument: $1"; exit 1 ;;
    esac
done

# ── 0. Verify sudo ────────────────────────────────────────────────────────────
echo "=== NitroWebExpress — MySQL Setup ==="
echo ""
echo "[0/5] Checking sudo privileges..."
if ! sudo -v 2>/dev/null; then
    echo "ERROR: sudo privileges are required to install and configure MySQL."
    echo "       Run this script as a user with sudo access, or prefix with: sudo -E bash bash/mysql-setup.sh"
    exit 1
fi
# Keep sudo timestamp alive in the background for long installs
( while true; do sudo -v; sleep 50; done ) &
SUDO_KEEP_PID=$!
trap "kill $SUDO_KEEP_PID 2>/dev/null || true" EXIT
echo "      sudo OK."

# ── 1. Install MySQL ──────────────────────────────────────────────────────────
echo ""
echo "[1/5] Installing MySQL Server..."
if dpkg -s mysql-server &>/dev/null; then
    echo "      mysql-server is already installed — skipping apt install."
else
    sudo apt-get update -y
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y mysql-server
    echo "      Installed."
fi

# ── 2. Enable and start the service ──────────────────────────────────────────
echo ""
echo "[2/5] Enabling and starting MySQL service..."
sudo systemctl enable mysql
sudo systemctl start  mysql
# Wait up to 15s for the socket to appear
for i in $(seq 1 15); do
    sudo mysqladmin ping --silent 2>/dev/null && break
    sleep 1
done
if ! sudo mysqladmin ping --silent 2>/dev/null; then
    echo "ERROR: MySQL did not become ready within 15 seconds."
    exit 1
fi
echo "      MySQL is running."

# ── 3. Create database and application user ───────────────────────────────────
echo ""
echo "[3/5] Creating database '$DB_NAME' and user '$APP_USER'..."
sudo mysql --batch <<SQL
CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\`
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

CREATE USER IF NOT EXISTS '${APP_USER}'@'localhost' IDENTIFIED BY '${APP_PASS}';

GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${APP_USER}'@'localhost';

FLUSH PRIVILEGES;
SQL
echo "      Database and user configured."

# ── 4. Build application tables ───────────────────────────────────────────────
echo ""
echo "[4/5] Building N21 application tables..."
TABLE_BUILDER="$ROOT/scripts/N21.table.builder.sh"
if [[ ! -f "$TABLE_BUILDER" ]]; then
    echo "      WARNING: $TABLE_BUILDER not found — skipping table creation."
else
    chmod +x "$TABLE_BUILDER"
    bash "$TABLE_BUILDER"
    echo "      Tables created."
fi

# ── 5. Write auth XML (only if absent) ───────────────────────────────────────
echo ""
echo "[5/5] Checking authentication/mysql.auth.xml..."
if [[ -f "$AUTH_FILE" ]]; then
    echo "      $AUTH_FILE already exists — not overwriting."
else
    mkdir -p "$(dirname "$AUTH_FILE")"
    cat > "$AUTH_FILE" <<XML
<?xml version="1.0" encoding="UTF-8"?>
<mysql-auth>
    <host>localhost</host>
    <port>3306</port>
    <username>${APP_USER}</username>
    <password>${APP_PASS}</password>
    <use-sudo>true</use-sudo>
</mysql-auth>
XML
    chmod 600 "$AUTH_FILE"
    echo "      Written: $AUTH_FILE"
fi

echo ""
echo "=== MySQL setup complete. ==="
echo "    Host     : localhost:3306"
echo "    Database : $DB_NAME"
echo "    User     : $APP_USER"
echo "    Auth XML : $AUTH_FILE"
