#!/usr/bin/env bash
# Brarner.M.Alete™ — Populate Publications Database (macOS)
# Usage: bash install/macos/populate-publications.sh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BMA_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
DB_PROPS="$BMA_ROOT/servlets/servlet/src/main/webapp/WEB-INF/db.properties"
DATA_CSV="$BMA_ROOT/data/publications/publications.csv"

if [ ! -f "$DB_PROPS" ]; then echo "[!] db.properties not found."; exit 1; fi

DB_USER=$(grep '^db.user=' "$DB_PROPS" | cut -d= -f2-)
DB_PASS=$(grep '^db.password=' "$DB_PROPS" | cut -d= -f2-)
MYSQL_CMD="mysql -u${DB_USER}"
[ -n "$DB_PASS" ] && MYSQL_CMD="$MYSQL_CMD -p${DB_PASS}"

echo "═══════════════════════════════════════════════════════════════"
echo " Brarner.M.Alete™ — Populate Publications Database (macOS)"
echo "═══════════════════════════════════════════════════════════════"

$MYSQL_CMD BrarnerScience -e "ALTER TABLE publications ADD COLUMN IF NOT EXISTS abstract_text TEXT AFTER year_published;" 2>/dev/null || true

if [ ! -f "$DATA_CSV" ] || [ ! -s "$DATA_CSV" ]; then
    echo "[WARN] No publications CSV: $DATA_CSV"
    exit 1
fi

echo "[*] Loading publications from CSV..."
TMP_SQL="/tmp/bma-pubs.sql"
echo "USE BrarnerScience; TRUNCATE TABLE publications;" > "$TMP_SQL"
tail -n +2 "$DATA_CSV" | while IFS=',' read -r source title authors doi year abstract; do
    source="${source//\'/\\\'}" title="${title//\'/\\\'}" authors="${authors//\'/\\\'}" doi="${doi//\'/\\\'}" abstract="${abstract//\'/\\\'}"
    echo "INSERT INTO publications(source_name,title,authors,doi,year_published,abstract_text) VALUES('$source','$title','$authors','$doi','$year','$abstract');" >> "$TMP_SQL"
done
$MYSQL_CMD < "$TMP_SQL"
rm -f "$TMP_SQL"
ROWS=$($MYSQL_CMD -N -e "SELECT COUNT(*) FROM BrarnerScience.publications;")
echo "[OK] publications table: $ROWS rows"
echo "═══════════════════════════════════════════════════════════════"
