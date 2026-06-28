#!/bin/bash
# Brarner.M.Alete™ — Populate SSA Data (Linux/macOS)
# Creates SSA table and seeds with office location data.
# Usage: bash install/populate-ssa.sh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BMA_ROOT="$(dirname "$SCRIPT_DIR")"
DB_PROPS="$BMA_ROOT/servlets/servlet/src/main/webapp/WEB-INF/db.properties"

echo "═══════════════════════════════════════════════════════════════"
echo " Brarner.M.Alete™ — Populate SSA Database"
echo "═══════════════════════════════════════════════════════════════"

if [ ! -f "$DB_PROPS" ]; then echo "[!] db.properties not found."; exit 1; fi

DB_USER=$(grep '^db.user=' "$DB_PROPS" | cut -d= -f2-)
DB_PASS=$(grep '^db.password=' "$DB_PROPS" | cut -d= -f2-)
MYSQL_CMD="mysql -u${DB_USER}"
[ -n "$DB_PASS" ] && MYSQL_CMD="$MYSQL_CMD -p${DB_PASS}"

# Create SSA table
echo "[*] Creating SSA table..."
$MYSQL_CMD BrarnerScience <<'SQL'
CREATE TABLE IF NOT EXISTS ssa_offices (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    office_name VARCHAR(255),
    address VARCHAR(500),
    city VARCHAR(100),
    state VARCHAR(50),
    zip_code VARCHAR(10),
    phone VARCHAR(30),
    office_type VARCHAR(50),
    INDEX idx_state (state),
    INDEX idx_city (city)
);
SQL

# Check for CSV data or seed from source/ssa configs
SSA_SRC="$BMA_ROOT/source/ssa"
DATA_CSV="$BMA_ROOT/data/ssa/ssa-offices.csv"
mkdir -p "$BMA_ROOT/data/ssa"

if [ -f "$DATA_CSV" ] && [ -s "$DATA_CSV" ]; then
    echo "[*] Loading SSA data from CSV..."
    $MYSQL_CMD BrarnerScience -e "TRUNCATE TABLE ssa_offices;"
    tail -n +2 "$DATA_CSV" | while IFS=',' read -r name addr city state zip phone type; do
        name="${name//\'/\\\'}" addr="${addr//\'/\\\'}" city="${city//\'/\\\'}"
        $MYSQL_CMD BrarnerScience -e "INSERT INTO ssa_offices(office_name,address,city,state,zip_code,phone,office_type) VALUES('$name','$addr','$city','$state','$zip','$phone','$type');"
    done
elif [ -d "$SSA_SRC" ]; then
    echo "[*] Scanning source/ssa config.xml files..."
    $MYSQL_CMD BrarnerScience -e "TRUNCATE TABLE ssa_offices;"
    find "$SSA_SRC" -name "config.xml" -type f | while read -r cfg; do
        CITY=$(grep -oP '(?<=<socket-host>)[^<]*' "$cfg" 2>/dev/null | head -1)
        STATE=$(basename "$(dirname "$(dirname "$cfg")")")
        OFFICE=$(basename "$(dirname "$cfg")")
        ADDR=$(grep -oP '(?<=<address>)[^<]*' "$cfg" 2>/dev/null | head -1)
        PORT=$(grep -oP '(?<=<socket-port>)[^<]*' "$cfg" 2>/dev/null | head -1)
        OFFICE="${OFFICE//\'/\\\'}" ADDR="${ADDR//\'/\\\'}"
        $MYSQL_CMD BrarnerScience -e "INSERT INTO ssa_offices(office_name,city,state,office_type) VALUES('$OFFICE','$OFFICE','$STATE','field');" 2>/dev/null || true
    done
    ROWS=$($MYSQL_CMD -N -e "SELECT COUNT(*) FROM BrarnerScience.ssa_offices;")
    echo "[OK] ssa_offices: $ROWS rows (from source/ssa configs)"
else
    echo "[*] No data source found — seeding with sample SSA offices..."
    $MYSQL_CMD BrarnerScience <<'SQL'
INSERT IGNORE INTO ssa_offices (office_name, address, city, state, zip_code, phone, office_type) VALUES
('Durham NC','2414 Durham-Chapel Hill Blvd','Durham','NC','27707','1-877-405-3253','field'),
('Raleigh NC','4701 Old Wake Forest Rd','Raleigh','NC','27609','1-877-803-6514','field'),
('Charlotte NC','5701 Executive Center Dr','Charlotte','NC','28212','1-866-964-1627','field'),
('Hickory NC','1985 Tate Blvd SE','Hickory','NC','28602','1-877-628-6705','field'),
('Apache Junction AZ','253 W Superstition Blvd','Apache Junction','AZ','85120','1-800-772-1213','field'),
('Twin Falls ID','1441 Fillmore St','Twin Falls','ID','83301','1-866-583-3520','field'),
('Cocoa FL','1580 Clearlake Rd','Cocoa','FL','32922','1-888-397-5599','field'),
('West Palm Beach FL','1591 Belvedere Rd','West Palm Beach','FL','33406','1-888-279-9519','field'),
('Lawrenceburg TN','2285 Buffalo Rd','Lawrenceburg','TN','38464','1-877-405-0457','field');
SQL
    ROWS=$($MYSQL_CMD -N -e "SELECT COUNT(*) FROM BrarnerScience.ssa_offices;")
    echo "[OK] ssa_offices seeded: $ROWS rows"
fi

echo "═══════════════════════════════════════════════════════════════"
