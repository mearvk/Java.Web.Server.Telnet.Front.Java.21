#!/bin/bash
# ============================================================================
# Brarner.M.Alete™ — Download Taxonomy Descriptions from GBIF (v3)
# Uses GBIF Species API — inserts into MySQL as it goes, skips existing entries
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BMA_ROOT="$(dirname "$SCRIPT_DIR")"
DB_PROPS="$BMA_ROOT/servlets/servlet/src/main/webapp/WEB-INF/db.properties"
TMPFILE="/tmp/gbif-response.json"

echo "═══════════════════════════════════════════════════════════════"
echo " Brarner.M.Alete™ — Download Taxonomy Descriptions (GBIF v3)"
echo "═══════════════════════════════════════════════════════════════"

# ─── Read DB credentials (prompt user) ───
if [ -f "$DB_PROPS" ]; then
    DEFAULT_USER=$(grep '^db.user=' "$DB_PROPS" | cut -d= -f2-)
    DEFAULT_HOST=$(grep '^db.url=' "$DB_PROPS" | sed -n 's|.*://\([^:/]*\).*|\1|p')
    DEFAULT_PORT=$(grep '^db.url=' "$DB_PROPS" | sed -n 's|.*:\([0-9]*\)/.*|\1|p')
    DEFAULT_HOST="${DEFAULT_HOST:-127.0.0.1}"
    DEFAULT_PORT="${DEFAULT_PORT:-3306}"
else
    DEFAULT_USER="root"
    DEFAULT_HOST="127.0.0.1"
    DEFAULT_PORT="3306"
fi

echo ""
read -rp "  MySQL username [${DEFAULT_USER}]: " DB_USER
DB_USER="${DB_USER:-$DEFAULT_USER}"
read -srp "  MySQL password: " DB_PASS
echo ""
read -rp "  MySQL host [${DEFAULT_HOST}]: " DB_HOST
DB_HOST="${DB_HOST:-$DEFAULT_HOST}"
read -rp "  MySQL port [${DEFAULT_PORT}]: " DB_PORT
DB_PORT="${DB_PORT:-$DEFAULT_PORT}"
echo ""

# ─── MySQL helper function (handles special chars in password) ───
run_mysql() {
    mysql --user="$DB_USER" --password="$DB_PASS" --host="$DB_HOST" --port="$DB_PORT" --database="BrarnerScience" "$@" 2>/dev/null
}

# ─── Verify MySQL connectivity ───
echo "[*] Testing MySQL connection..."
if ! run_mysql -e "SELECT 1;" >/dev/null 2>&1; then
    echo "[!] Cannot connect to MySQL. Check db.properties credentials."
    exit 1
fi
echo "[✓] MySQL connection OK"

# ─── Ensure gbif_key column exists (MySQL 8.0 compatible) ───
HAS_GBIF_KEY=$(run_mysql -N -B -e "SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='BrarnerScience' AND TABLE_NAME='taxonomy_descriptions' AND COLUMN_NAME='gbif_key';")
if [ "$HAS_GBIF_KEY" = "0" ]; then
    echo "[*] Adding gbif_key column..."
    run_mysql -e "ALTER TABLE taxonomy_descriptions ADD COLUMN gbif_key INT;"
fi

GBIF_API="https://api.gbif.org/v1"
TOTAL_INSERTED=0
TOTAL_SKIPPED=0
TOTAL_FAILED=0

# ─── Core: fetch from GBIF and insert into DB ───
fetch_and_insert() {
    local rank_level="$1"
    local taxon_name="$2"
    local safe_name
    safe_name=$(echo "$taxon_name" | sed "s/'/''/g")

    # Skip if already exists in DB
    local cnt
    cnt=$(run_mysql -N -B -e "SELECT COUNT(*) FROM taxonomy_descriptions WHERE rank_level='${rank_level}' AND taxon_name='${safe_name}';")
    if [ "$cnt" -gt 0 ] 2>/dev/null; then
        TOTAL_SKIPPED=$((TOTAL_SKIPPED + 1))
        return 0
    fi

    # Map rank to GBIF format
    local gbif_rank
    gbif_rank=$(echo "$rank_level" | tr '[:lower:]' '[:upper:]')

    # URL-encode the taxon name
    local encoded
    encoded=$(python3 -c "import urllib.parse, sys; print(urllib.parse.quote(sys.argv[1]))" "$taxon_name" 2>/dev/null)

    # Fetch from GBIF
    curl -s --max-time 10 "${GBIF_API}/species/search?q=${encoded}&rank=${gbif_rank}&limit=1" -o "$TMPFILE" 2>/dev/null
    local curl_rc=$?

    if [ $curl_rc -ne 0 ] || [ ! -s "$TMPFILE" ]; then
        TOTAL_FAILED=$((TOTAL_FAILED + 1))
        return 1
    fi

    # Parse JSON and build INSERT statement with python3
    local sql
    sql=$(python3 - "$TMPFILE" "$rank_level" "$safe_name" << 'PYEOF'
import json, sys

try:
    tmpfile = sys.argv[1]
    rank_level = sys.argv[2]
    safe_name = sys.argv[3]

    with open(tmpfile) as f:
        data = json.load(f)
    results = data.get("results", [])
    if not results:
        sys.exit(1)
    r = results[0]
    key = r.get("key", 0)
    canonical = r.get("canonicalName", r.get("scientificName", ""))
    rank_str = r.get("rank", "").lower()
    num_desc = r.get("numDescendants", 0)
    status = r.get("taxonomicStatus", "")

    # Build description
    desc = f"{canonical} is a {rank_str}"
    if r.get("kingdom"): desc += f" in kingdom {r['kingdom']}"
    if r.get("phylum"): desc += f", phylum {r['phylum']}"
    if num_desc:
        desc += f". Contains approximately {num_desc} known descendant taxa"
    desc += "."
    if status:
        desc += f" Taxonomic status: {status}."

    # Lineage as characteristics
    parts = []
    for k in ["kingdom", "phylum", "class", "order", "family"]:
        if r.get(k): parts.append(f"{k.title()}: {r[k]}")
    lineage = ", ".join(parts)

    wiki = f"https://en.wikipedia.org/wiki/{canonical.replace(' ', '_')}"

    # Escape for SQL
    desc = desc.replace("\\", "\\\\").replace("'", "''")[:1000]
    lineage = lineage.replace("'", "''")[:500]
    safe_name = safe_name.replace("\\", "\\\\")

    print(f"INSERT INTO taxonomy_descriptions (rank_level, taxon_name, description, characteristics, wikipedia_url, gbif_key) VALUES('{rank_level}', '{safe_name}', '{desc}', '{lineage}', '{wiki}', {key}) ON DUPLICATE KEY UPDATE description=VALUES(description), characteristics=VALUES(characteristics), wikipedia_url=VALUES(wikipedia_url), gbif_key=VALUES(gbif_key);")
except Exception as e:
    sys.exit(1)
PYEOF
    )

    if [ -n "$sql" ]; then
        if run_mysql -e "$sql"; then
            TOTAL_INSERTED=$((TOTAL_INSERTED + 1))
            return 0
        else
            TOTAL_FAILED=$((TOTAL_FAILED + 1))
            return 1
        fi
    else
        TOTAL_FAILED=$((TOTAL_FAILED + 1))
        return 1
    fi
}

# ─── Phase 1: Classes ───
echo ""
echo "[1/3] Classes..."
CLASS_LIST=$(run_mysql -N -B -e "SELECT DISTINCT class_name FROM animalia WHERE class_name IS NOT NULL AND class_name!='' ORDER BY class_name;")
C=0
CT=$(echo "$CLASS_LIST" | grep -c .)
while IFS= read -r t; do
    [ -z "$t" ] && continue
    C=$((C + 1))
    printf "\r    [%d/%d] %-40s" "$C" "$CT" "$t"
    fetch_and_insert "class" "$t"
    sleep 0.3
done <<< "$CLASS_LIST"
echo ""
echo "    Classes done: $TOTAL_INSERTED inserted, $TOTAL_SKIPPED skipped, $TOTAL_FAILED failed"

# ─── Phase 2: Orders ───
echo ""
echo "[2/3] Orders..."
BATCH_INS=$TOTAL_INSERTED
BATCH_SKIP=$TOTAL_SKIPPED
BATCH_FAIL=$TOTAL_FAILED
ORDER_LIST=$(run_mysql -N -B -e "SELECT DISTINCT order_name FROM animalia WHERE order_name IS NOT NULL AND order_name!='' ORDER BY order_name;")
C=0
CT=$(echo "$ORDER_LIST" | grep -c .)
while IFS= read -r t; do
    [ -z "$t" ] && continue
    C=$((C + 1))
    [ $((C % 5)) -eq 0 ] || [ $C -eq 1 ] && printf "\r    [%d/%d] %-40s" "$C" "$CT" "$t"
    fetch_and_insert "order" "$t"
    sleep 0.3
done <<< "$ORDER_LIST"
echo ""
echo "    Orders done: $((TOTAL_INSERTED - BATCH_INS)) inserted, $((TOTAL_SKIPPED - BATCH_SKIP)) skipped, $((TOTAL_FAILED - BATCH_FAIL)) failed"

# ─── Phase 3: Families ───
echo ""
echo "[3/3] Families (largest batch — ~15 min)..."
BATCH_INS=$TOTAL_INSERTED
BATCH_SKIP=$TOTAL_SKIPPED
BATCH_FAIL=$TOTAL_FAILED
FAMILY_LIST=$(run_mysql -N -B -e "SELECT DISTINCT family_name FROM animalia WHERE family_name IS NOT NULL AND family_name!='' ORDER BY family_name;")
C=0
CT=$(echo "$FAMILY_LIST" | grep -c .)
while IFS= read -r t; do
    [ -z "$t" ] && continue
    C=$((C + 1))
    [ $((C % 20)) -eq 0 ] || [ $C -eq 1 ] && printf "\r    [%d/%d] %-40s" "$C" "$CT" "$t"
    fetch_and_insert "family" "$t"
    sleep 0.3
done <<< "$FAMILY_LIST"
echo ""
echo "    Families done: $((TOTAL_INSERTED - BATCH_INS)) inserted, $((TOTAL_SKIPPED - BATCH_SKIP)) skipped, $((TOTAL_FAILED - BATCH_FAIL)) failed"

# ─── Summary ───
rm -f "$TMPFILE"
FINAL=$(run_mysql -N -B -e "SELECT COUNT(*) FROM taxonomy_descriptions;")
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo " [✓] Complete — $FINAL total records in taxonomy_descriptions"
run_mysql -N -B -e "SELECT CONCAT('     ', rank_level, ': ', COUNT(*)) FROM taxonomy_descriptions GROUP BY rank_level;"
echo ""
echo "     Total inserted this run: $TOTAL_INSERTED"
echo "     Total skipped (existed): $TOTAL_SKIPPED"
echo "     Total failed:            $TOTAL_FAILED"
echo "═══════════════════════════════════════════════════════════════"
