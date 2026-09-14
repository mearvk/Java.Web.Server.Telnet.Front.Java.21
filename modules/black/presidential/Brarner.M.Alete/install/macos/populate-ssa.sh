#!/usr/bin/env bash
# ⚠️  DESTRUCTIVE: This script TRUNCATES tables before reloading data.
# Do NOT run as part of git-pull automation. Run manually only when reloading reference data.
# Brarner.M.Alete™ — Populate SSA Database (macOS)
# Usage: bash install/macos/populate-ssa.sh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BMA_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
DB_PROPS="$BMA_ROOT/servlets/servlet/src/main/webapp/WEB-INF/db.properties"
DATA_CSV="$BMA_ROOT/data/ssa/ssa-offices.csv"

if [ ! -f "$DB_PROPS" ]; then echo "[!] db.properties not found."; exit 1; fi

DB_USER=$(grep '^db.user=' "$DB_PROPS" | cut -d= -f2-)
DB_PASS=$(grep '^db.password=' "$DB_PROPS" | cut -d= -f2-)
MYSQL_CMD="mysql -u${DB_USER}"
[ -n "$DB_PASS" ] && MYSQL_CMD="$MYSQL_CMD -p${DB_PASS}"

echo "═══════════════════════════════════════════════════════════════"
echo " Brarner.M.Alete™ — Populate SSA Database (macOS)"
echo "═══════════════════════════════════════════════════════════════"

$MYSQL_CMD BrarnerScience -e "CREATE TABLE IF NOT EXISTS ssa_offices (id BIGINT AUTO_INCREMENT PRIMARY KEY, office_name VARCHAR(255), address VARCHAR(500), city VARCHAR(100), state VARCHAR(50), zip_code VARCHAR(10), phone VARCHAR(30), office_type VARCHAR(50), INDEX idx_state(state), INDEX idx_city(city));" 2>/dev/null

if [ ! -f "$DATA_CSV" ] || [ ! -s "$DATA_CSV" ]; then
    echo "[WARN] No SSA CSV: $DATA_CSV"
    exit 1
fi

echo "[*] Loading SSA data from CSV..."
TMP_SQL="/tmp/bma-ssa.sql"
echo "USE BrarnerScience; TRUNCATE TABLE ssa_offices;" > "$TMP_SQL"
tail -n +2 "$DATA_CSV" | while IFS=',' read -r name addr city state zip phone type; do
    name="${name//\'/\\\'}" addr="${addr//\"/}" addr="${addr//\'/\\\'}" city="${city//\'/\\\'}"
    echo "INSERT INTO ssa_offices(office_name,address,city,state,zip_code,phone,office_type) VALUES('$name','$addr','$city','$state','$zip','$phone','$type');" >> "$TMP_SQL"
done
$MYSQL_CMD < "$TMP_SQL"
rm -f "$TMP_SQL"
ROWS=$($MYSQL_CMD -N -e "SELECT COUNT(*) FROM BrarnerScience.ssa_offices;")
echo "[OK] ssa_offices: $ROWS rows"
echo "═══════════════════════════════════════════════════════════════"
