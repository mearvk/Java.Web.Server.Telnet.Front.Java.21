#!/bin/bash
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

# Download free US ZIP code CSV if not present
ZIP_CSV="$DATA_DIR/us-zip-codes.csv"
if [ ! -f "$ZIP_CSV" ]; then
    echo "[*] Downloading US ZIP code data..."
    curl -sfL "https://raw.githubusercontent.com/scpike/us-state-county-zip/master/geo-data.csv" -o "$ZIP_CSV" 2>/dev/null || \
    curl -sfL "https://gist.githubusercontent.com/erichurst/7882666/raw/5bdc46db47d9515269ab12ed6fb2850377fd869e/US%20Zip%20Codes%20from%202013%20Government%20Data" -o "$ZIP_CSV" 2>/dev/null || true
fi

if [ -f "$ZIP_CSV" ] && [ -s "$ZIP_CSV" ]; then
    echo "[*] Loading postal data from CSV..."
    $MYSQL_CMD BrarnerScience -e "TRUNCATE TABLE postal;"
    $MYSQL_CMD BrarnerScience -e "LOAD DATA LOCAL INFILE '$ZIP_CSV' INTO TABLE postal FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '\"' LINES TERMINATED BY '\n' IGNORE 1 LINES (zip_code, city, state, county, latitude, longitude);" 2>/dev/null || \
    $MYSQL_CMD --local-infile=1 BrarnerScience -e "LOAD DATA LOCAL INFILE '$ZIP_CSV' INTO TABLE postal FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '\"' LINES TERMINATED BY '\n' IGNORE 1 LINES (zip_code, city, state, county, latitude, longitude);" 2>/dev/null || {
        echo "[*] LOAD DATA failed — using INSERT fallback..."
        TMP_SQL="/tmp/bma-postal.sql"
        echo "USE BrarnerScience; TRUNCATE TABLE postal;" > "$TMP_SQL"
        tail -n +2 "$ZIP_CSV" | head -50000 | while IFS=',' read -r zip city state county lat lon; do
            zip="${zip//\'/\\\'}" city="${city//\'/\\\'}" state="${state//\'/\\\'}" county="${county//\'/\\\'}"
            echo "INSERT INTO postal(zip_code,city,state,county,latitude,longitude) VALUES('$zip','$city','$state','$county',$lat,$lon);" >> "$TMP_SQL"
        done
        $MYSQL_CMD < "$TMP_SQL"
        rm -f "$TMP_SQL"
    }
    ROWS=$($MYSQL_CMD -N -e "SELECT COUNT(*) FROM BrarnerScience.postal;")
    echo "[OK] postal table: $ROWS rows"
else
    echo "[WARN] No postal CSV found. Add us-zip-codes.csv to $DATA_DIR"
    echo "       Format: zip_code,city,state,county,latitude,longitude"
fi

echo "═══════════════════════════════════════════════════════════════"
