#!/usr/bin/env bash
# ⚠️  DESTRUCTIVE: This script TRUNCATES tables before reloading data.
# Do NOT run as part of git-pull automation. Run manually only when reloading reference data.
# Brarner.M.Alete™ — Populate Art Database (macOS)
# Usage: bash install/macos/populate-art.sh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BMA_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
DB_PROPS="$BMA_ROOT/servlets/servlet/src/main/webapp/WEB-INF/db.properties"
DATA_CSV="$BMA_ROOT/data/art/art-works.csv"

if [ ! -f "$DB_PROPS" ]; then echo "[!] db.properties not found."; exit 1; fi

DB_USER=$(grep '^db.user=' "$DB_PROPS" | cut -d= -f2-)
DB_PASS=$(grep '^db.password=' "$DB_PROPS" | cut -d= -f2-)
MYSQL_CMD="mysql -u${DB_USER}"
[ -n "$DB_PASS" ] && MYSQL_CMD="$MYSQL_CMD -p${DB_PASS}"

echo "═══════════════════════════════════════════════════════════════"
echo " Brarner.M.Alete™ — Populate Art Database (macOS)"
echo "═══════════════════════════════════════════════════════════════"

$MYSQL_CMD BrarnerScience -e "ALTER TABLE art_works ADD COLUMN IF NOT EXISTS collection VARCHAR(100) AFTER museum_name;" 2>/dev/null || true

if [ ! -f "$DATA_CSV" ] || [ ! -s "$DATA_CSV" ]; then
    echo "[WARN] No art CSV: $DATA_CSV"
    exit 1
fi

echo "[*] Loading art data from CSV..."
TMP_SQL="/tmp/bma-art.sql"
echo "USE BrarnerScience; TRUNCATE TABLE art_works;" > "$TMP_SQL"
tail -n +2 "$DATA_CSV" | while IFS=',' read -r museum title artist year medium collection; do
    museum="${museum//\'/\\\'}" title="${title//\'/\\\'}" artist="${artist//\'/\\\'}" medium="${medium//\'/\\\'}" collection="${collection//\'/\\\'}"
    echo "INSERT INTO art_works(museum_name,title,artist,year_created,medium,collection) VALUES('$museum','$title','$artist','$year','$medium','$collection');" >> "$TMP_SQL"
done
$MYSQL_CMD < "$TMP_SQL"
rm -f "$TMP_SQL"
ROWS=$($MYSQL_CMD -N -e "SELECT COUNT(*) FROM BrarnerScience.art_works;")
echo "[OK] art_works table: $ROWS rows"
echo "═══════════════════════════════════════════════════════════════"
