#!/bin/bash
# ============================================================================
# Brarner.M.Alete™ — Fix 'Updating' Placeholder Descriptions
# Finds all taxonomy_descriptions rows where description = 'Updating' and
# fetches real descriptions from GBIF Species API to replace them.
# Safe to run multiple times — only touches rows with placeholder text.
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BMA_ROOT="$(dirname "$SCRIPT_DIR")"
DB_PROPS="$BMA_ROOT/servlets/servlet/src/main/webapp/WEB-INF/db.properties"
TMPFILE="/tmp/gbif-fix-response.json"

echo "═══════════════════════════════════════════════════════════════"
echo " Brarner.M.Alete™ — Fix 'Updating' Placeholder Descriptions"
echo "═══════════════════════════════════════════════════════════════"

# ─── Read DB credentials ───
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

# ─── MySQL helper ───
run_mysql() {
    mysql --user="$DB_USER" --password="$DB_PASS" --host="$DB_HOST" --port="$DB_PORT" --database="BrarnerScience" "$@" 2>/dev/null
}

# ─── Verify connectivity ───
echo "[*] Testing MySQL connection..."
if ! run_mysql -e "SELECT 1;" >/dev/null 2>&1; then
    echo "[!] Cannot connect to MySQL. Check credentials."
    exit 1
fi
echo "[✓] MySQL connection OK"

# ─── Count placeholder entries ───
UPDATING_COUNT=$(run_mysql -N -B -e "SELECT COUNT(*) FROM taxonomy_descriptions WHERE description='Updating' OR description IS NULL OR TRIM(description)='';")
TOTAL_COUNT=$(run_mysql -N -B -e "SELECT COUNT(*) FROM taxonomy_descriptions;")

echo ""
echo "[*] Found $UPDATING_COUNT / $TOTAL_COUNT entries needing real descriptions"
echo ""

if [ "$UPDATING_COUNT" = "0" ]; then
    echo "[✓] All descriptions are already populated. Nothing to fix."
    exit 0
fi

# ─── Show breakdown ───
echo "    Breakdown by rank:"
run_mysql -N -B -e "SELECT CONCAT('      ', rank_level, ': ', COUNT(*)) FROM taxonomy_descriptions WHERE description='Updating' OR description IS NULL OR TRIM(description)='' GROUP BY rank_level ORDER BY rank_level;"
echo ""

GBIF_API="https://api.gbif.org/v1"
FIXED=0
FAILED=0
SKIPPED=0

# ─── Fetch from GBIF and update existing row ───
fix_description() {
    local rank_level="$1"
    local taxon_name="$2"

    # Map rank to GBIF format
    local gbif_rank
    gbif_rank=$(echo "$rank_level" | tr '[:lower:]' '[:upper:]')

    # URL-encode the taxon name
    local encoded
    encoded=$(python3 -c "import urllib.parse, sys; print(urllib.parse.quote(sys.argv[1]))" "$taxon_name" 2>/dev/null)

    if [ -z "$encoded" ]; then
        FAILED=$((FAILED + 1))
        return 1
    fi

    # Fetch from GBIF
    local http_code
    http_code=$(curl -s -w "%{http_code}" --max-time 15 "${GBIF_API}/species/search?q=${encoded}&rank=${gbif_rank}&limit=1" -o "$TMPFILE" 2>/dev/null)

    if [ "$http_code" != "200" ] || [ ! -s "$TMPFILE" ]; then
        FAILED=$((FAILED + 1))
        return 1
    fi

    # Parse JSON and build UPDATE statement
    local sql
    sql=$(python3 - "$TMPFILE" "$rank_level" "$taxon_name" << 'PYEOF'
import json, sys

try:
    tmpfile = sys.argv[1]
    rank_level = sys.argv[2]
    taxon_name = sys.argv[3]

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
    if r.get("kingdom"):
        desc += f" in kingdom {r['kingdom']}"
    if r.get("phylum"):
        desc += f", phylum {r['phylum']}"
    if rank_str in ("class", "order", "family") and r.get("class") and r.get("class") != canonical:
        desc += f", class {r['class']}"
    if rank_str in ("order", "family") and r.get("order") and r.get("order") != canonical:
        desc += f", order {r['order']}"
    if num_desc:
        desc += f". Contains approximately {num_desc:,} known descendant taxa"
    desc += "."
    if status:
        desc += f" Taxonomic status: {status}."

    # Lineage as characteristics
    parts = []
    for k in ["kingdom", "phylum", "class", "order", "family"]:
        if r.get(k):
            parts.append(f"{k.title()}: {r[k]}")
    lineage = ", ".join(parts)

    wiki = f"https://en.wikipedia.org/wiki/{canonical.replace(' ', '_')}"

    # Escape for SQL
    desc = desc.replace("\\", "\\\\").replace("'", "''")[:2000]
    lineage = lineage.replace("\\", "\\\\").replace("'", "''")[:500]
    safe_name = taxon_name.replace("\\", "\\\\").replace("'", "''")

    print(f"UPDATE taxonomy_descriptions SET description='{desc}', characteristics='{lineage}', wikipedia_url='{wiki}', gbif_key={key} WHERE rank_level='{rank_level}' AND taxon_name='{safe_name}';")
except Exception:
    sys.exit(1)
PYEOF
    )

    if [ -n "$sql" ]; then
        if run_mysql -e "$sql"; then
            FIXED=$((FIXED + 1))
            return 0
        else
            FAILED=$((FAILED + 1))
            return 1
        fi
    else
        FAILED=$((FAILED + 1))
        return 1
    fi
}

# ─── Process all 'Updating' entries ───
echo "[*] Fetching real descriptions from GBIF..."
echo ""

# Read entries as tab-separated rank_level and taxon_name
ENTRIES=$(run_mysql -N -B -e "SELECT rank_level, taxon_name FROM taxonomy_descriptions WHERE description='Updating' OR description IS NULL OR TRIM(description)='' ORDER BY FIELD(rank_level,'kingdom','phylum','class','order','family'), taxon_name;")

CURRENT=0
while IFS=$'\t' read -r rank_level taxon_name; do
    [ -z "$rank_level" ] && continue
    [ -z "$taxon_name" ] && continue
    CURRENT=$((CURRENT + 1))
    printf "\r    [%d/%d] %-12s %-40s" "$CURRENT" "$UPDATING_COUNT" "$rank_level" "$taxon_name"
    fix_description "$rank_level" "$taxon_name"
    sleep 0.4  # Rate-limit GBIF API calls
done <<< "$ENTRIES"

echo ""
echo ""

# ─── Verify results ───
REMAINING=$(run_mysql -N -B -e "SELECT COUNT(*) FROM taxonomy_descriptions WHERE description='Updating' OR description IS NULL OR TRIM(description)='';")
POPULATED=$(run_mysql -N -B -e "SELECT COUNT(*) FROM taxonomy_descriptions WHERE description!='Updating' AND description IS NOT NULL AND TRIM(description)!='';")

echo "═══════════════════════════════════════════════════════════════"
echo " [✓] Fix Complete"
echo ""
echo "     Fixed this run:       $FIXED"
echo "     Failed (no GBIF hit): $FAILED"
echo "     Total populated now:  $POPULATED / $TOTAL_COUNT"
echo "     Still 'Updating':     $REMAINING"
echo ""

if [ "$REMAINING" -gt 0 ]; then
    echo "     Remaining 'Updating' entries:"
    run_mysql -N -B -e "SELECT CONCAT('       ', rank_level, ' — ', taxon_name) FROM taxonomy_descriptions WHERE description='Updating' OR description IS NULL OR TRIM(description)='' ORDER BY rank_level, taxon_name LIMIT 50;"
    OVER50=$(run_mysql -N -B -e "SELECT COUNT(*) FROM taxonomy_descriptions WHERE description='Updating' OR description IS NULL OR TRIM(description)='';")
    if [ "$OVER50" -gt 50 ]; then
        echo "       ... and $((OVER50 - 50)) more"
    fi
    echo ""
    echo "     These taxa may not exist in GBIF or have non-standard names."
    echo "     Consider manually populating or checking taxon spelling."
fi
echo "═══════════════════════════════════════════════════════════════"

# ─── Cleanup ───
rm -f "$TMPFILE"
