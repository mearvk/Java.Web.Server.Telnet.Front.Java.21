#!/bin/bash
# ============================================================================
# NWE Subject/Object Discovery — Noun Extractor
# Scans source directories for data patterns (CSV headers, XML elements, Java
# classes) and generates a website-config.xml suitable for generate-website.sh.
#
# Usage:
#   bash scripts/discover-subjects.sh <source-dir> [module-name] [color]
#
# Example:
#   bash scripts/discover-subjects.sh source/city-analysis CityAnalysis "#d97706"
#
# Output: scripts/website-subjects/<module-name>.xml
#
# What it discovers:
#   - CSV files → column headers become table columns (nouns)
#   - XML config files → element names become content headers (pages)
#   - Java source files → class names suggest module structure
#   - .sql files → existing table definitions
#
# Author: Max Rupplin — MEARVK LLC
# ============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

SOURCE_DIR="${1:-.}"
MODULE_NAME="${2:-DiscoveredModule}"
MODULE_COLOR="${3:-#3b82f6}"

OUT_DIR="$SCRIPT_DIR/website-subjects"
mkdir -p "$OUT_DIR"
OUT_FILE="$OUT_DIR/${MODULE_NAME}.xml"

echo "═══════════════════════════════════════════════════════════════"
echo " NWE Subject/Object Discovery"
echo " Scanning: $SOURCE_DIR"
echo " Module:   $MODULE_NAME"
echo " Output:   $OUT_FILE"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# ─── Discover CSVs (nouns = table columns) ───
echo "[1] Scanning CSV files for nouns..."
NOUNS=""
CSV_COUNT=0
while IFS= read -r csv_file; do
    CSV_COUNT=$((CSV_COUNT + 1))
    FILENAME=$(basename "$csv_file" .csv)
    # Sanitize to valid table name
    TABLE_NAME=$(echo "$FILENAME" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9_' '_' | sed 's/^_//;s/_$//')
    # Get header row
    HEADER=$(head -1 "$csv_file" | tr -d '\r')
    # Convert to column list
    COLUMNS=$(echo "$HEADER" | sed 's/,/,/g')
    if [ -n "$TABLE_NAME" ] && [ -n "$COLUMNS" ]; then
        NOUNS+="        <noun name=\"${TABLE_NAME}\" table=\"${MODULE_NAME,,}_${TABLE_NAME}\" columns=\"${COLUMNS}\"/>\n"
        echo "    [CSV] $FILENAME → ${MODULE_NAME,,}_${TABLE_NAME} ($(echo "$COLUMNS" | tr ',' '\n' | wc -l) cols)"
    fi
done < <(find "$SOURCE_DIR" -name "*.csv" -type f 2>/dev/null | head -20)
echo "    Found: $CSV_COUNT CSV files"

# ─── Discover XML configs (pages = content sections) ───
echo ""
echo "[2] Scanning XML for content headers..."
PAGES=""
PAGE_COUNT=0
# Look for config files that define sections/instances
while IFS= read -r xml_file; do
    # Extract instance/section names
    while IFS= read -r instance; do
        iname=$(echo "$instance" | grep -oP 'name="\K[^"]+' | head -1)
        iport=$(echo "$instance" | grep -oP 'port="\K[^"]+' | head -1)
        if [ -n "$iname" ]; then
            PAGE_COUNT=$((PAGE_COUNT + 1))
            PAGES+="        <page name=\"${iname^}\" file=\"${iname}\" port=\"${iport:-0}\"/>\n"
        fi
    done < <(grep -i '<instance\|<section\|<module\|<page' "$xml_file" 2>/dev/null | head -15)
done < <(find "$SOURCE_DIR" -name "*.xml" -name "*config*" -type f 2>/dev/null | head -10)

# If no config XMLs, infer pages from subdirectories
if [ "$PAGE_COUNT" -eq 0 ]; then
    echo "    No config.xml found. Inferring from directory structure..."
    PORT=$((19000))
    while IFS= read -r dir; do
        DIRNAME=$(basename "$dir")
        PAGES+="        <page name=\"${DIRNAME^}\" file=\"${DIRNAME}\" port=\"${PORT}\"/>\n"
        PORT=$((PORT + 1))
        PAGE_COUNT=$((PAGE_COUNT + 1))
    done < <(find "$SOURCE_DIR" -maxdepth 1 -type d ! -name "$(basename "$SOURCE_DIR")" 2>/dev/null | sort | head -10)
fi
echo "    Found: $PAGE_COUNT pages/sections"

# ─── Discover Java classes (additional structure hints) ───
echo ""
echo "[3] Scanning Java classes..."
JAVA_COUNT=0
while IFS= read -r java_file; do
    CLASSNAME=$(basename "$java_file" .java)
    JAVA_COUNT=$((JAVA_COUNT + 1))
    echo "    [Java] $CLASSNAME"
done < <(find "$SOURCE_DIR" -name "*.java" -type f 2>/dev/null | head -10)
echo "    Found: $JAVA_COUNT Java files"

# ─── Discover SQL (existing tables) ───
echo ""
echo "[4] Scanning SQL schemas..."
while IFS= read -r sql_file; do
    TABLES=$(grep -oP 'CREATE TABLE[^(]+\K\w+' "$sql_file" 2>/dev/null | head -10)
    for T in $TABLES; do
        echo "    [SQL] Existing table: $T"
    done
done < <(find "$SOURCE_DIR" -name "*.sql" -type f 2>/dev/null | head -5)

# ─── Assign default port range ───
PORT_START=19000
PORT_END=$((PORT_START + PAGE_COUNT + 5))

# ─── Always include standard pages ───
STANDARD_PAGES="        <page name=\"Overview\" file=\"index\" default=\"true\"/>\n"
STANDARD_PAGES+="        <page name=\"Status\" file=\"status\"/>\n"

# ─── Write config XML ───
echo ""
echo "[5] Writing config: $OUT_FILE"

cat > "$OUT_FILE" << XMLEOF
<?xml version="1.0" encoding="UTF-8"?>
<!--
    NWE Website Config — Auto-discovered from: $SOURCE_DIR
    Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)
    Module: $MODULE_NAME
    
    Edit this file to refine pages, nouns, and port assignments.
    Then run: bash scripts/generate-website.sh $MODULE_NAME $OUT_FILE
-->
<website-config>
    <module name="$MODULE_NAME" color="$MODULE_COLOR" database="nwe_${MODULE_NAME,,}"/>
    <ports start="$PORT_START" end="$PORT_END"/>
    <pages>
$(echo -e "$STANDARD_PAGES")
$(echo -e "$PAGES")
    </pages>
    <nouns>
$(echo -e "$NOUNS")
    </nouns>
</website-config>
XMLEOF

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo " [✓] Subject discovery complete"
echo ""
echo "     Config:  $OUT_FILE"
echo "     Pages:   $PAGE_COUNT discovered + 2 standard"
echo "     Nouns:   $CSV_COUNT tables from CSV headers"
echo ""
echo "     Next: bash scripts/generate-website.sh $MODULE_NAME $OUT_FILE"
echo "═══════════════════════════════════════════════════════════════"
