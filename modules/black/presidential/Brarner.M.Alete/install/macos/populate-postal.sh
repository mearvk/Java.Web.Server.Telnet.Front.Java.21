#!/usr/bin/env bash
# Brarner.M.Alete™ — Populate Postal Database (macOS)
# Usage: bash install/macos/populate-postal.sh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BMA_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
DB_PROPS="$BMA_ROOT/servlets/servlet/src/main/webapp/WEB-INF/db.properties"
DATA_CSV="$BMA_ROOT/data/postal/us-zip-codes.csv"

if [ ! -f "$DB_PROPS" ]; then echo "[!] db.properties not found."; exit 1; fi

DB_USER=$(grep '^db.user=' "$DB_PROPS" | cut -d= -f2-)
DB_PASS=$(grep '^db.password=' "$DB_PROPS" | cut -d= -f2-)
MYSQL_CMD="mysql -u${DB_USER}"
[ -n "$DB_PASS" ] && MYSQL_CMD="$MYSQL_CMD -p${DB_PASS}"

echo "═══════════════════════════════════════════════════════════════"
echo " Brarner.M.Alete™ — Populate Postal Database (macOS)"
echo "═══════════════════════════════════════════════════════════════"

$MYSQL_CMD BrarnerScience -e "ALTER TABLE postal ADD COLUMN IF NOT EXISTS latitude DECIMAL(9,6) AFTER county; ALTER TABLE postal ADD COLUMN IF NOT EXISTS longitude DECIMAL(9,6) AFTER latitude;" 2>/dev/null || true

if [ ! -f "$DATA_CSV" ] || [ ! -s "$DATA_CSV" ]; then
    echo "[WARN] No postal CSV: $DATA_CSV"
    exit 1
fi

echo "[*] Loading postal data from CSV..."
TMP_SQL="/tmp/bma-postal.sql"
echo "USE BrarnerScience; TRUNCATE TABLE postal;" > "$TMP_SQL"
tail -n +2 "$DATA_CSV" | while IFS=',' read -r zip city state county lat lon; do
    zip="${zip//\'/\\\'}" city="${city//\'/\\\'}" state="${state//\'/\\\'}" county="${county//\'/\\\'}"
    echo "INSERT INTO postal(zip_code,city,state,county,latitude,longitude) VALUES('$zip','$city','$state','$county',$lat,$lon);" >> "$TMP_SQL"
done
$MYSQL_CMD < "$TMP_SQL"
rm -f "$TMP_SQL"
ROWS=$($MYSQL_CMD -N -e "SELECT COUNT(*) FROM BrarnerScience.postal;")
echo "[OK] postal table: $ROWS rows"
echo "═══════════════════════════════════════════════════════════════"
