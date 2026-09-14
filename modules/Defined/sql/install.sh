#!/bin/bash
# ============================================================================
# Defined Module — Database Installer
# Creates 'defined_dark_gray' database and runs schema.sql
# NitroWebExpress™ — MEARVK LLC
# ============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCHEMA_FILE="${SCRIPT_DIR}/schema.sql"

echo "============================================"
echo "  Defined Module — Database Installation"
echo "  Database: defined_dark_gray"
echo "============================================"

# Check schema file exists
if [ ! -f "$SCHEMA_FILE" ]; then
  echo "[ERROR] schema.sql not found at: $SCHEMA_FILE"
  exit 1
fi

# Prompt for MySQL root credentials
read -p "MySQL root user [root]: " MYSQL_USER
MYSQL_USER="${MYSQL_USER:-root}"

read -sp "MySQL root password: " MYSQL_PASS
echo ""

# Create database and run schema
echo "[1/3] Creating database 'defined_dark_gray'..."
mysql -u "$MYSQL_USER" -p"$MYSQL_PASS" -e "CREATE DATABASE IF NOT EXISTS defined_dark_gray CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"

echo "[2/3] Running schema.sql..."
mysql -u "$MYSQL_USER" -p"$MYSQL_PASS" < "$SCHEMA_FILE"

echo "[3/3] Creating application user 'nwe_defined'..."
mysql -u "$MYSQL_USER" -p"$MYSQL_PASS" -e "
  CREATE USER IF NOT EXISTS 'nwe_defined'@'localhost' IDENTIFIED BY 'CHANGE_ME';
  GRANT SELECT, INSERT ON defined_dark_gray.* TO 'nwe_defined'@'localhost';
  FLUSH PRIVILEGES;
"

echo ""
echo "[OK] Database 'defined_dark_gray' installed successfully."
echo "[REMINDER] Change the nwe_defined password and set NWE_DEFINED_DB_PASS env variable."
echo "============================================"
