#!/bin/bash
# ============================================================================
# Brarner.M.Alete™ — Download Taxonomy Descriptions (v4)
# Uses Wikipedia Summary API for real English descriptions, GBIF for lineage.
# Inserts into MySQL as it goes, skips entries that already have real content.
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BMA_ROOT="$(dirname "$SCRIPT_DIR")"
DB_PROPS="$BMA_ROOT/servlets/servlet/src/main/webapp/WEB-INF/db.properties"
TMPFILE="/tmp/gbif-response.json"

echo "═══════════════════════════════════════════════════════════════"
echo " Brarner.M.Alete™ — Download Taxonomy Descriptions (v4)"
echo " Sources: Wikipedia Summary API + GBIF Species API"
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

# ─── Pre-download stats ───
TOTAL_COUNT=$(run_mysql -N -B -e "SELECT COUNT(*) FROM taxonomy_descriptions;")
POPULATED_COUNT=$(run_mysql -N -B -e "SELECT COUNT(*) FROM taxonomy_descriptions WHERE description IS NOT NULL AND description!='Updating' AND TRIM(description)!='';")
UPDATING_COUNT=$(run_mysql -N -B -e "SELECT COUNT(*) FROM taxonomy_descriptions WHERE description='Updating' OR description IS NULL OR TRIM(description)='';")

echo ""
echo "[*] Current state:"
echo "     Total entries:             $TOTAL_COUNT"
echo "     Already populated:         $POPULATED_COUNT"
echo "     Needing download:          $UPDATING_COUNT"
echo ""
echo "    Populated breakdown by rank:"
run_mysql -N -B -e "SELECT CONCAT('      ', rank_level, ': ', COUNT(*)) FROM taxonomy_descriptions WHERE description IS NOT NULL AND description!='Updating' AND TRIM(description)!='' GROUP BY rank_level ORDER BY rank_level;"
echo ""

GBIF_API="https://api.gbif.org/v1"
WIKI_API="https://en.wikipedia.org/api/rest_v1/page/summary"
TOTAL_INSERTED=0
TOTAL_SKIPPED=0
TOTAL_FAILED=0

# ─── Core: fetch description from Wikipedia + lineage from GBIF ───
fetch_and_insert() {
    local rank_level="$1"
    local taxon_name="$2"
    local safe_name
    safe_name=$(echo "$taxon_name" | sed "s/'/''/g")

    # Skip if already has a real description (not 'Updating' or empty)
    local existing_desc
    existing_desc=$(run_mysql -N -B -e "SELECT description FROM taxonomy_descriptions WHERE rank_level='${rank_level}' AND taxon_name='${safe_name}' LIMIT 1;")
    if [ -n "$existing_desc" ] && [ "$existing_desc" != "Updating" ] && [ "$existing_desc" != "NULL" ]; then
        TOTAL_SKIPPED=$((TOTAL_SKIPPED + 1))
        return 0
    fi

    # URL-encode the taxon name
    local encoded
    encoded=$(python3 -c "import urllib.parse, sys; print(urllib.parse.quote(sys.argv[1]))" "$taxon_name" 2>/dev/null)

    if [ -z "$encoded" ]; then
        TOTAL_FAILED=$((TOTAL_FAILED + 1))
        return 1
    fi

    # Fetch from Wikipedia Summary API (primary source for description)
    local wiki_tmp="/tmp/wiki-response.json"
    curl -s --max-time 10 -H "User-Agent: BrarnerMAlete/1.0 (taxonomy-descriptions)" \
        "${WIKI_API}/${encoded}" -o "$wiki_tmp" 2>/dev/null

    # Fetch from GBIF (for lineage/characteristics and gbif_key)
    local gbif_rank
    gbif_rank=$(echo "$rank_level" | tr '[:lower:]' '[:upper:]')
    curl -s --max-time 10 "${GBIF_API}/species/search?q=${encoded}&rank=${gbif_rank}&limit=1" -o "$TMPFILE" 2>/dev/null

    # Parse both responses and build SQL
    local sql
    sql=$(python3 - "$wiki_tmp" "$TMPFILE" "$rank_level" "$safe_name" "$taxon_name" << 'PYEOF'
import json, sys, os

try:
    wiki_file = sys.argv[1]
    gbif_file = sys.argv[2]
    rank_level = sys.argv[3]
    safe_name = sys.argv[4]
    taxon_name = sys.argv[5]

    desc = ""
    wiki_url = ""
    characteristics = ""
    gbif_key = 0

    # ── Wikipedia: get the real English description ──
    if os.path.exists(wiki_file) and os.path.getsize(wiki_file) > 0:
        with open(wiki_file) as f:
            try:
                wd = json.load(f)
                if wd.get("type") != "not_found" and wd.get("extract"):
                    desc = wd["extract"]
                    # Trim to first 2-3 sentences for DB storage (max 2000 chars)
                    if len(desc) > 2000:
                        # Cut at last sentence boundary before 2000
                        cut = desc[:2000].rfind(". ")
                        if cut > 200:
                            desc = desc[:cut+1]
                        else:
                            desc = desc[:2000]
                    wiki_url = wd.get("content_urls", {}).get("desktop", {}).get("page", "")
                    if not wiki_url:
                        wiki_url = f"https://en.wikipedia.org/wiki/{taxon_name.replace(' ', '_')}"
            except (json.JSONDecodeError, KeyError):
                pass

    # ── GBIF: get lineage and key ──
    if os.path.exists(gbif_file) and os.path.getsize(gbif_file) > 0:
        with open(gbif_file) as f:
            try:
                gd = json.load(f)
                results = gd.get("results", [])
                if results:
                    r = results[0]
                    gbif_key = r.get("nubKey", r.get("key", 0))

                    # Build characteristics from lineage
                    parts = []
                    for k in ["kingdom", "phylum", "class", "order", "family"]:
                        if r.get(k):
                            parts.append(f"{k.title()}: {r[k]}")
                    characteristics = ", ".join(parts)

                    # If Wikipedia had nothing, build a basic description from GBIF
                    if not desc:
                        canonical = r.get("canonicalName", r.get("scientificName", taxon_name))
                        rank_str = r.get("rank", "").lower()
                        num_desc_count = r.get("numDescendants", 0)
                        desc = f"{canonical} is a {rank_str}"
                        if r.get("kingdom"):
                            desc += f" in kingdom {r['kingdom']}"
                        if r.get("phylum"):
                            desc += f", phylum {r['phylum']}"
                        if num_desc_count:
                            desc += f". Contains approximately {num_desc_count:,} known descendant taxa"
                        desc += "."
                        wiki_url = f"https://en.wikipedia.org/wiki/{canonical.replace(' ', '_')}"
            except (json.JSONDecodeError, KeyError):
                pass

    # Must have at least some description
    if not desc:
        sys.exit(1)

    # Escape for SQL
    desc = desc.replace("\\", "\\\\").replace("'", "''")
    characteristics = characteristics.replace("\\", "\\\\").replace("'", "''")[:500]
    wiki_url = wiki_url.replace("'", "''")[:500]
    safe_name = safe_name.replace("\\", "\\\\")

    print(f"INSERT INTO taxonomy_descriptions (rank_level, taxon_name, description, characteristics, wikipedia_url, gbif_key) VALUES('{rank_level}', '{safe_name}', '{desc}', '{characteristics}', '{wiki_url}', {gbif_key}) ON DUPLICATE KEY UPDATE description=VALUES(description), characteristics=VALUES(characteristics), wikipedia_url=VALUES(wikipedia_url), gbif_key=VALUES(gbif_key);")
except Exception:
    sys.exit(1)
PYEOF
    )

    rm -f "$wiki_tmp"

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
