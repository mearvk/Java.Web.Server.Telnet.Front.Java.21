#!/bin/bash
# Brarner.M.Alete™ — Create Science Database
# Checks for existing database before creating a new one.
# Usage: bash install/run_create_science_db.sh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BMA_ROOT="$(dirname "$SCRIPT_DIR")"
CONFIG_DIR="$BMA_ROOT/configuration"
DB_PROPS="$BMA_ROOT/servlets/servlet/src/main/webapp/WEB-INF/db.properties"

echo "═══════════════════════════════════════════════════════════════"
echo " Brarner.M.Alete™ — Create Science Database"
echo "═══════════════════════════════════════════════════════════════"

# Determine credentials — prefer db.properties, fall back to .my.cnf
MYSQL_OPTS=""
if [ -f "$DB_PROPS" ]; then
    DB_USER=$(grep '^db.user=' "$DB_PROPS" | cut -d= -f2-)
    DB_PASS=$(grep '^db.password=' "$DB_PROPS" | cut -d= -f2-)
    DB_HOST=$(grep '^db.url=' "$DB_PROPS" | sed -n 's|.*://\([^:/]*\).*|\1|p')
    DB_PORT=$(grep '^db.url=' "$DB_PROPS" | sed -n 's|.*:\([0-9]*\)/.*|\1|p')
    DB_HOST="${DB_HOST:-localhost}"
    DB_PORT="${DB_PORT:-3306}"
    MYSQL_OPTS="-u${DB_USER} -h${DB_HOST} -P${DB_PORT}"
    [ -n "$DB_PASS" ] && MYSQL_OPTS="$MYSQL_OPTS -p${DB_PASS}"
    echo "[*] Using credentials from db.properties (user=$DB_USER host=$DB_HOST:$DB_PORT)"
elif [ -f "$CONFIG_DIR/.my.cnf" ]; then
    MYSQL_OPTS="--defaults-extra-file=$CONFIG_DIR/.my.cnf"
    echo "[*] Using credentials from .my.cnf"
else
    echo "[!] No credentials found. Run install.sh first or create db.properties."
    exit 1
fi

# Check if database already exists
DB_NAME="BrarnerScience"
echo ""
echo "[*] Checking if database '$DB_NAME' exists..."
EXISTS=$(mysql $MYSQL_OPTS -N -e "SELECT SCHEMA_NAME FROM information_schema.SCHEMATA WHERE SCHEMA_NAME='$DB_NAME'" 2>/dev/null)

if [ "$EXISTS" = "$DB_NAME" ]; then
    echo "[OK] Database '$DB_NAME' already exists."
    echo ""
    echo "     Tables:"
    mysql $MYSQL_OPTS -e "USE $DB_NAME; SHOW TABLES;" 2>/dev/null | sed 's/^/       /'
    echo ""
    echo "     Row counts:"
    mysql $MYSQL_OPTS -N -e "SELECT table_name, table_rows FROM information_schema.TABLES WHERE table_schema='$DB_NAME'" 2>/dev/null | sed 's/^/       /'
    echo ""
    echo "[*] Skipping creation — database intact."
else
    echo "[*] Database '$DB_NAME' not found. Creating..."

    SQL_FILE="$SCRIPT_DIR/create_science_db.sql"
    if [ ! -f "$SQL_FILE" ]; then
        echo "[!] SQL file not found: $SQL_FILE"
        exit 1
    fi

    mysql $MYSQL_OPTS < "$SQL_FILE"

    if [ $? -eq 0 ]; then
        echo "[OK] Database '$DB_NAME' created successfully."
        echo ""
        echo "     Tables:"
        mysql $MYSQL_OPTS -e "USE $DB_NAME; SHOW TABLES;" 2>/dev/null | sed 's/^/       /'
    else
        echo "[FAIL] Database creation failed."
        echo "       Check credentials and MySQL status."
        exit 1
    fi
fi

echo ""
echo "═══════════════════════════════════════════════════════════════"
