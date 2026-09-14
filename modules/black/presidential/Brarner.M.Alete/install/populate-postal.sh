#!/bin/bash
# ⚠️  DESTRUCTIVE: This script TRUNCATES/DROPS tables before reloading data.
# Do NOT run as part of git-pull automation. Run manually only when reloading reference data.
# Brarner.M.Alete™ — Populate Postal Data (Linux/macOS)
# Downloads US ZIP code data and inserts into BrarnerScience.postal
# Usage: bash install/populate-postal.sh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BMA_ROOT="$(dirname "$SCRIPT_DIR")"
DB_PROPS="$BMA_ROOT/servlets/servlet/src/main/webapp/WEB-INF/db.properties"
DATA_DIR="$BMA_ROOT/data/postal"

echo "═══════════════════════════════════════════════════════════════"
echo " Brarner.M.Alete™ — Populate Postal Database"
echo "═══════════════════════════════════════════════════════════════"

if [ ! -f "$DB_PROPS" ]; then
    echo "[!] db.properties not found. Run install script first."
    exit 1
fi

DB_USER=$(grep '^db.user=' "$DB_PROPS" | cut -d= -f2-)
DB_PASS=$(grep '^db.password=' "$DB_PROPS" | cut -d= -f2-)
MYSQL_CMD="mysql -u${DB_USER}"
[ -n "$DB_PASS" ] && MYSQL_CMD="$MYSQL_CMD -p${DB_PASS}"

mkdir -p "$DATA_DIR"

# Use the full US ZIP code CSV (33K+ records, all states)
ZIP_CSV="$DATA_DIR/us-all-states-zip.csv"
if [ ! -f "$ZIP_CSV" ]; then
    echo "[*] Downloading US ZIP code data (all states)..."
    curl -sfL "https://raw.githubusercontent.com/conradhopp/usa-data/master/US%20ZIP%20Lng%20Lat%20City%20County.csv" -o "$ZIP_CSV" || {
        echo "[FAIL] Download failed"; exit 1; }
fi

if [ -f "$ZIP_CSV" ] && [ -s "$ZIP_CSV" ]; then
    echo "[*] Loading postal data from CSV ($(wc -l < "$ZIP_CSV") lines)..."
    $MYSQL_CMD BrarnerScience <<'SQL'
DROP TABLE IF EXISTS postal;
CREATE TABLE postal (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    zip_code VARCHAR(10),
    city VARCHAR(100),
    state VARCHAR(50),
    county VARCHAR(100),
    latitude DECIMAL(9,6),
    longitude DECIMAL(9,6),
    INDEX idx_state (state),
    INDEX idx_zip (zip_code)
);
SQL
    # CSV format: ZIP,LAT,LNG,City,State,County — reorder to our schema
    # Try LOAD DATA first (fastest), fall back to batch INSERT
    $MYSQL_CMD --local-infile=1 BrarnerScience -e "LOAD DATA LOCAL INFILE '$ZIP_CSV' INTO TABLE postal FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '\"' LINES TERMINATED BY '\r\n' IGNORE 1 LINES (@zip, @lat, @lng, @city, @state, @county) SET zip_code=@zip, latitude=@lat, longitude=@lng, city=@city, state=TRIM(@state), county=@county;" 2>/dev/null || \
    $MYSQL_CMD BrarnerScience -e "LOAD DATA LOCAL INFILE '$ZIP_CSV' INTO TABLE postal FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '\"' LINES TERMINATED BY '\r\n' IGNORE 1 LINES (@zip, @lat, @lng, @city, @state, @county) SET zip_code=@zip, latitude=@lat, longitude=@lng, city=@city, state=TRIM(@state), county=@county;" 2>/dev/null || {
        echo "[*] LOAD DATA failed — using batch INSERT fallback..."
        TMP_SQL="/tmp/bma-postal.sql"
        echo "USE BrarnerScience;" > "$TMP_SQL"
        # Process CSV: ZIP,LAT,LNG,City,State,County
        tail -n +2 "$ZIP_CSV" | tr -d '\r' | while IFS=',' read -r zip lat lng city state county; do
            city="${city//\'/\\\'}" county="${county//\'/\\\'}" state="$(echo "$state" | tr -d ' ')"
            echo "INSERT INTO postal(zip_code,city,state,county,latitude,longitude) VALUES('$zip','$city','$state','$county',$lat,$lng);" >> "$TMP_SQL"
        done
        $MYSQL_CMD < "$TMP_SQL"
        rm -f "$TMP_SQL"
    }
    ROWS=$($MYSQL_CMD -N -e "SELECT COUNT(*) FROM BrarnerScience.postal;")
    echo "[OK] postal table: $ROWS rows"
else
    echo "[FAIL] No postal CSV found at $ZIP_CSV"
    exit 1
fi

echo "═══════════════════════════════════════════════════════════════"
