#!/bin/bash
# Brarner.M.Alete™ — Populate Science Database from CSV/XML source data
# Reads species config.xml files and inserts into BrarnerScience.animalia
# Usage: bash install/populate-science-db.sh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BMA_ROOT="$(dirname "$SCRIPT_DIR")"
DB_PROPS="$BMA_ROOT/servlets/servlet/src/main/webapp/WEB-INF/db.properties"
SPECIES_DIR="$BMA_ROOT/source/species"

echo "═══════════════════════════════════════════════════════════════"
echo " Brarner.M.Alete™ — Populate Science Database"
echo "═══════════════════════════════════════════════════════════════"

# Read DB credentials
if [ -f "$DB_PROPS" ]; then
    DB_USER=$(grep '^db.user=' "$DB_PROPS" | cut -d= -f2-)
    DB_PASS=$(grep '^db.password=' "$DB_PROPS" | cut -d= -f2-)
    DB_HOST=$(grep '^db.url=' "$DB_PROPS" | sed -n 's|.*://\([^:/]*\).*|\1|p')
    DB_PORT=$(grep '^db.url=' "$DB_PROPS" | sed -n 's|.*:\([0-9]*\)/.*|\1|p')
    DB_HOST="${DB_HOST:-localhost}"
    DB_PORT="${DB_PORT:-3306}"
    MYSQL_OPTS="-u${DB_USER} -h${DB_HOST} -P${DB_PORT}"
    [ -n "$DB_PASS" ] && MYSQL_OPTS="$MYSQL_OPTS -p${DB_PASS}"
    echo "[*] Credentials from db.properties (user=$DB_USER)"
else
    echo "[!] db.properties not found. Run install.sh first."
    exit 1
fi

# Create BrarnerScience database and animalia/species tables if not exist
echo "[*] Ensuring BrarnerScience database and tables..."
mysql $MYSQL_OPTS <<'SQL'
CREATE DATABASE IF NOT EXISTS BrarnerScience;
USE BrarnerScience;

CREATE TABLE IF NOT EXISTS animalia (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    kingdom VARCHAR(100),
    phylum VARCHAR(100),
    subphylum VARCHAR(100),
    class_name VARCHAR(100),
    subclass VARCHAR(100),
    order_name VARCHAR(100),
    suborder VARCHAR(100),
    infraorder VARCHAR(100),
    family_name VARCHAR(100),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_kingdom (kingdom),
    INDEX idx_class (class_name),
    INDEX idx_order (order_name),
    INDEX idx_family (family_name)
);

CREATE TABLE IF NOT EXISTS species (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    kingdom VARCHAR(100),
    phylum VARCHAR(100),
    class_name VARCHAR(100),
    order_name VARCHAR(100),
    family_name VARCHAR(100),
    species_name VARCHAR(255),
    common_name VARCHAR(255),
    description TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_family (family_name),
    INDEX idx_species (species_name)
);

CREATE TABLE IF NOT EXISTS postal (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    zip_code VARCHAR(10),
    city VARCHAR(100),
    state VARCHAR(50),
    county VARCHAR(100),
    INDEX idx_state (state),
    INDEX idx_zip (zip_code)
);

CREATE TABLE IF NOT EXISTS art_works (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    museum_name VARCHAR(255),
    title VARCHAR(500),
    artist VARCHAR(255),
    year_created VARCHAR(20),
    medium VARCHAR(255),
    INDEX idx_museum (museum_name)
);

CREATE TABLE IF NOT EXISTS publications (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    source_name VARCHAR(255),
    title VARCHAR(500),
    authors TEXT,
    doi VARCHAR(255),
    year_published VARCHAR(10),
    INDEX idx_source (source_name)
);
SQL
echo "[OK] Tables ready."

# Parse species config.xml files and insert into animalia
echo ""
echo "[*] Scanning species config.xml files in $SPECIES_DIR..."

if [ ! -d "$SPECIES_DIR" ]; then
    echo "[!] Species source directory not found: $SPECIES_DIR"
    exit 1
fi

# Count configs
CONFIG_COUNT=$(find "$SPECIES_DIR" -name "config.xml" | wc -l)
echo "[*] Found $CONFIG_COUNT config.xml files"

# Build bulk SQL insert
TMP_SQL="/tmp/bma-populate-animalia.sql"
echo "USE BrarnerScience;" > "$TMP_SQL"
echo "TRUNCATE TABLE animalia;" >> "$TMP_SQL"
echo "INSERT INTO animalia (kingdom, phylum, subphylum, class_name, subclass, order_name, suborder, infraorder, family_name) VALUES" >> "$TMP_SQL"

FIRST=true
INSERTED=0

while IFS= read -r cfg; do
    # Extract fields from XML using grep/sed (no xmllint dependency)
    KINGDOM=$(grep -oP '(?<=<kingdom>)[^<]*' "$cfg" 2>/dev/null | head -1)
    PHYLUM=$(grep -oP '(?<=<phylum>)[^<]*' "$cfg" 2>/dev/null | head -1)
    SUBPHYLUM=$(grep -oP '(?<=<subphylum>)[^<]*' "$cfg" 2>/dev/null | head -1)
    CLASS=$(grep -oP '(?<=<class-name>)[^<]*' "$cfg" 2>/dev/null | head -1)
    SUBCLASS=$(grep -oP '(?<=<subclass>)[^<]*' "$cfg" 2>/dev/null | head -1)
    ORDER=$(grep -oP '(?<=<order>)[^<]*' "$cfg" 2>/dev/null | head -1)
    SUBORDER=$(grep -oP '(?<=<suborder>)[^<]*' "$cfg" 2>/dev/null | head -1)
    INFRAORDER=$(grep -oP '(?<=<infraorder>)[^<]*' "$cfg" 2>/dev/null | head -1)
    FAMILY=$(grep -oP '(?<=<family>)[^<]*' "$cfg" 2>/dev/null | head -1)

    # Skip if no useful data
    [ -z "$KINGDOM" ] && [ -z "$CLASS" ] && [ -z "$FAMILY" ] && continue

    # Escape single quotes
    KINGDOM="${KINGDOM//\'/\\\'}"
    PHYLUM="${PHYLUM//\'/\\\'}"
    SUBPHYLUM="${SUBPHYLUM//\'/\\\'}"
    CLASS="${CLASS//\'/\\\'}"
    SUBCLASS="${SUBCLASS//\'/\\\'}"
    ORDER="${ORDER//\'/\\\'}"
    SUBORDER="${SUBORDER//\'/\\\'}"
    INFRAORDER="${INFRAORDER//\'/\\\'}"
    FAMILY="${FAMILY//\'/\\\'}"

    if [ "$FIRST" = true ]; then
        FIRST=false
    else
        echo "," >> "$TMP_SQL"
    fi
    printf "('%s','%s','%s','%s','%s','%s','%s','%s','%s')" \
        "$KINGDOM" "$PHYLUM" "$SUBPHYLUM" "$CLASS" "$SUBCLASS" "$ORDER" "$SUBORDER" "$INFRAORDER" "$FAMILY" >> "$TMP_SQL"
    INSERTED=$((INSERTED + 1))

done < <(find "$SPECIES_DIR" -name "config.xml" -type f)

echo ";" >> "$TMP_SQL"

echo "[*] Inserting $INSERTED records into animalia..."
mysql $MYSQL_OPTS < "$TMP_SQL"
echo "[OK] animalia table populated."

# Show summary
echo ""
echo "[*] Summary:"
mysql $MYSQL_OPTS -e "USE BrarnerScience; SELECT kingdom, COUNT(DISTINCT class_name) AS classes, COUNT(DISTINCT order_name) AS orders, COUNT(DISTINCT family_name) AS families, COUNT(*) AS total_rows FROM animalia GROUP BY kingdom;"

rm -f "$TMP_SQL"

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo " [✓] Population complete — $INSERTED records inserted"
echo "     species.jsp will now render data from the database."
echo "═══════════════════════════════════════════════════════════════"
