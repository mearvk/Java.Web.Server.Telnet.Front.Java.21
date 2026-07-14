#!/bin/bash
# ⚠️  DESTRUCTIVE: This script TRUNCATES/DROPS tables before reloading data.
# Do NOT run as part of git-pull automation. Run manually only when reloading reference data.
# ============================================================================
# Brarner.M.Alete™ — Populate Plantae, Fungi, Protista from GBIF
# Downloads taxonomy hierarchies (phylum → class → order → family) from the
# GBIF Species API and generates SQL bulk-insert files + runs them into MySQL.
# Produces the same level of detail as animalia-bulk-insert.sql.
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BMA_ROOT="$(dirname "$SCRIPT_DIR")"
DB_PROPS="$BMA_ROOT/servlets/servlet/src/main/webapp/WEB-INF/db.properties"
OUTPUT_DIR="$SCRIPT_DIR"

echo "═══════════════════════════════════════════════════════════════"
echo " Brarner.M.Alete™ — Populate Plantae, Fungi, Protista"
echo " Source: GBIF Species API (api.gbif.org)"
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

run_mysql() {
    mysql --user="$DB_USER" --password="$DB_PASS" --host="$DB_HOST" --port="$DB_PORT" --database="BrarnerScience" "$@" 2>/dev/null
}

# ─── Verify MySQL ───
echo "[*] Testing MySQL connection..."
if ! run_mysql -e "SELECT 1;" >/dev/null 2>&1; then
    echo "[!] Cannot connect to MySQL."
    exit 1
fi
echo "[✓] MySQL connection OK"

# ─── Ensure installer_tax_id column exists ───
HAS_INSTALLER=$(run_mysql -N -B -e "SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='BrarnerScience' AND TABLE_NAME='animalia' AND COLUMN_NAME='installer_tax_id';")
if [ "$HAS_INSTALLER" = "0" ]; then
    echo "[*] Adding installer_tax_id column..."
    run_mysql -e "ALTER TABLE animalia ADD COLUMN installer_tax_id VARCHAR(50);"
fi

# ─── Backfill kingdom='Animalia' for existing rows that have no kingdom set ───
NULLS=$(run_mysql -N -B -e "SELECT COUNT(*) FROM animalia WHERE kingdom IS NULL OR kingdom='';")
if [ "$NULLS" -gt 0 ]; then
    echo "[*] Backfilling kingdom='Animalia' for $NULLS existing rows..."
    run_mysql -e "UPDATE animalia SET kingdom='Animalia' WHERE kingdom IS NULL OR kingdom='';"
    echo "[✓] Backfill complete"
fi

# ─── GBIF API config ───
GBIF_API="https://api.gbif.org/v1"
# Kingdom keys in GBIF backbone
declare -A KINGDOM_KEYS=(["Plantae"]=6 ["Fungi"]=5 ["Protozoa"]=7)
declare -A KINGDOM_SQL_FILES=(["Plantae"]="plantae-bulk-insert.sql" ["Fungi"]="fungi-bulk-insert.sql" ["Protozoa"]="protista-bulk-insert.sql")

TOTAL_INSERTED=0
TMPFILE="/tmp/gbif-kingdom-response.json"

# ─── Fetch children at a given rank under a parent key ───
fetch_children() {
    local parent_key="$1"
    local rank="$2"
    local limit="${3:-500}"
    curl -s --max-time 30 "${GBIF_API}/species/${parent_key}/children?limit=${limit}" -o "$TMPFILE" 2>/dev/null
    if [ ! -s "$TMPFILE" ]; then
        echo ""
        return
    fi
    python3 -c "
import json, sys
with open('$TMPFILE') as f:
    d = json.load(f)
results = d.get('results', [])
for r in results:
    rk = r.get('rank', '').upper()
    if rk == '${rank}'.upper() or '${rank}' == 'ANY':
        name = r.get('canonicalName', r.get('scientificName', ''))
        key = r.get('key', 0)
        if name:
            print(f'{key}\t{name}')
" 2>/dev/null
}

# ─── Build SQL for a kingdom ───
build_kingdom_sql() {
    local kingdom="$1"
    local kingdom_key="$2"
    local sql_file="$OUTPUT_DIR/${KINGDOM_SQL_FILES[$kingdom]}"
    local count=0
    local batch_size=500
    local in_batch=0

    echo "[*] Building $kingdom taxonomy..."
    echo "USE BrarnerScience;" > "$sql_file"

    # Fetch phyla
    local phyla
    phyla=$(fetch_children "$kingdom_key" "PHYLUM")
    local phylum_count=$(echo "$phyla" | grep -c . 2>/dev/null || echo 0)
    echo "    Phyla found: $phylum_count"

    # Helper to write a row
    write_row() {
        local row="$1"
        if [ $in_batch -eq 0 ]; then
            echo "INSERT INTO animalia (kingdom, phylum, subphylum, class_name, subclass, order_name, suborder, infraorder, family_name, installer_tax_id) VALUES" >> "$sql_file"
        else
            printf "," >> "$sql_file"
        fi
        echo "$row" >> "$sql_file"
        in_batch=$((in_batch + 1))
        count=$((count + 1))
        if [ $in_batch -ge $batch_size ]; then
            echo ";" >> "$sql_file"
            in_batch=0
        fi
    }

    while IFS=$'\t' read -r phylum_key phylum_name; do
        [ -z "$phylum_key" ] && continue
        # Escape single quotes in names
        phylum_name="${phylum_name//\'/\'\'}"

        # Fetch classes under this phylum
        local classes
        classes=$(fetch_children "$phylum_key" "CLASS")
        sleep 0.2

        if [ -z "$classes" ]; then
            # No classes — try orders directly
            local orders
            orders=$(fetch_children "$phylum_key" "ORDER")
            sleep 0.2
            if [ -z "$orders" ]; then
                write_row "('$kingdom','$phylum_name','','','','','','','','MEARVK-LLC-2026')"
            else
                while IFS=$'\t' read -r order_key order_name; do
                    [ -z "$order_key" ] && continue
                    order_name="${order_name//\'/\'\'}"
                    local families
                    families=$(fetch_children "$order_key" "FAMILY")
                    sleep 0.15
                    if [ -z "$families" ]; then
                        write_row "('$kingdom','$phylum_name','','','','$order_name','','','','MEARVK-LLC-2026')"
                    else
                        while IFS=$'\t' read -r fam_key fam_name; do
                            [ -z "$fam_key" ] && continue
                            fam_name="${fam_name//\'/\'\'}"
                            write_row "('$kingdom','$phylum_name','','','','$order_name','','','$fam_name','MEARVK-LLC-2026')"
                        done <<< "$families"
                    fi
                done <<< "$orders"
            fi
            continue
        fi

        while IFS=$'\t' read -r class_key class_name; do
            [ -z "$class_key" ] && continue
            class_name="${class_name//\'/\'\'}"

            # Fetch orders under this class
            local orders
            orders=$(fetch_children "$class_key" "ORDER")
            sleep 0.2

            if [ -z "$orders" ]; then
                write_row "('$kingdom','$phylum_name','','$class_name','','','','','','MEARVK-LLC-2026')"
                continue
            fi

            while IFS=$'\t' read -r order_key order_name; do
                [ -z "$order_key" ] && continue
                order_name="${order_name//\'/\'\'}"

                # Fetch families under this order
                local families
                families=$(fetch_children "$order_key" "FAMILY")
                sleep 0.15

                if [ -z "$families" ]; then
                    write_row "('$kingdom','$phylum_name','','$class_name','','$order_name','','','','MEARVK-LLC-2026')"
                else
                    while IFS=$'\t' read -r fam_key fam_name; do
                        [ -z "$fam_key" ] && continue
                        fam_name="${fam_name//\'/\'\'}"
                        write_row "('$kingdom','$phylum_name','','$class_name','','$order_name','','','$fam_name','MEARVK-LLC-2026')"
                    done <<< "$families"
                fi
            done <<< "$orders"
        done <<< "$classes"

        printf "\r    [%s] %d records..." "$phylum_name" "$count"
    done <<< "$phyla"

    # Close any open batch
    if [ $in_batch -gt 0 ]; then
        echo ";" >> "$sql_file"
    fi

    echo ""
    echo "    [$kingdom] Total records: $count → $sql_file"
    TOTAL_INSERTED=$((TOTAL_INSERTED + count))
    return 0
}

# ─── Process each kingdom ───
echo ""
for kingdom in "Plantae" "Fungi" "Protozoa"; do
    build_kingdom_sql "$kingdom" "${KINGDOM_KEYS[$kingdom]}"
    echo ""
done

# ─── Load SQL into MySQL ───
echo "[*] Loading SQL files into MySQL..."
for kingdom in "Plantae" "Fungi" "Protozoa"; do
    sql_file="$OUTPUT_DIR/${KINGDOM_SQL_FILES[$kingdom]}"
    if [ -f "$sql_file" ] && [ -s "$sql_file" ]; then
        echo "    Loading $sql_file..."
        run_mysql < "$sql_file"
        if [ $? -eq 0 ]; then
            echo "    [✓] $kingdom loaded"
        else
            echo "    [!] $kingdom load failed — check SQL file"
        fi
    fi
done

# ─── Also populate taxonomy_descriptions defaults for new kingdoms ───
echo ""
echo "[*] Creating taxonomy_descriptions defaults for new kingdoms..."
run_mysql << 'SQL'
INSERT IGNORE INTO taxonomy_descriptions (rank_level, taxon_name, description)
SELECT 'kingdom', 'Plantae', 'Updating'
FROM dual WHERE NOT EXISTS (SELECT 1 FROM taxonomy_descriptions WHERE rank_level='kingdom' AND taxon_name='Plantae');

INSERT IGNORE INTO taxonomy_descriptions (rank_level, taxon_name, description)
SELECT 'kingdom', 'Fungi', 'Updating'
FROM dual WHERE NOT EXISTS (SELECT 1 FROM taxonomy_descriptions WHERE rank_level='kingdom' AND taxon_name='Fungi');

INSERT IGNORE INTO taxonomy_descriptions (rank_level, taxon_name, description)
SELECT 'kingdom', 'Protozoa', 'Updating'
FROM dual WHERE NOT EXISTS (SELECT 1 FROM taxonomy_descriptions WHERE rank_level='kingdom' AND taxon_name='Protozoa');

INSERT INTO taxonomy_descriptions (rank_level, taxon_name, description)
SELECT 'class', a.class_name, 'Updating'
FROM (SELECT DISTINCT class_name FROM animalia WHERE kingdom IN ('Plantae','Fungi','Protozoa') AND class_name IS NOT NULL AND class_name!='') a
LEFT JOIN taxonomy_descriptions td ON td.rank_level='class' AND td.taxon_name=a.class_name
WHERE td.id IS NULL;

INSERT INTO taxonomy_descriptions (rank_level, taxon_name, description)
SELECT 'order', a.order_name, 'Updating'
FROM (SELECT DISTINCT order_name FROM animalia WHERE kingdom IN ('Plantae','Fungi','Protozoa') AND order_name IS NOT NULL AND order_name!='') a
LEFT JOIN taxonomy_descriptions td ON td.rank_level='order' AND td.taxon_name=a.order_name
WHERE td.id IS NULL;

INSERT INTO taxonomy_descriptions (rank_level, taxon_name, description)
SELECT 'family', a.family_name, 'Updating'
FROM (SELECT DISTINCT family_name FROM animalia WHERE kingdom IN ('Plantae','Fungi','Protozoa') AND family_name IS NOT NULL AND family_name!='') a
LEFT JOIN taxonomy_descriptions td ON td.rank_level='family' AND td.taxon_name=a.family_name
WHERE td.id IS NULL;
SQL
echo "[✓] Taxonomy description defaults created"

# ─── Summary ───
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo " [✓] Complete"
echo ""
echo "     Total new records: $TOTAL_INSERTED"
echo ""
echo "     SQL files generated:"
echo "       $OUTPUT_DIR/plantae-bulk-insert.sql"
echo "       $OUTPUT_DIR/fungi-bulk-insert.sql"
echo "       $OUTPUT_DIR/protista-bulk-insert.sql"
echo ""
echo "     Database counts:"
run_mysql -N -B -e "SELECT CONCAT('       ', COALESCE(kingdom,'Animalia'), ': ', COUNT(*)) FROM animalia GROUP BY kingdom ORDER BY kingdom;"
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo " Next: Run download-taxonomy-descriptions.sh to fetch real"
echo " descriptions from Wikipedia for the new 'Updating' entries."
echo "═══════════════════════════════════════════════════════════════"

rm -f "$TMPFILE"
