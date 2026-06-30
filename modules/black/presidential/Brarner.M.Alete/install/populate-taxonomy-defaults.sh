#!/bin/bash
# ============================================================================
# Brarner.M.Alete™ — Populate Taxonomy Defaults (Remote Install)
# Ensures every taxon in animalia has an entry in taxonomy_descriptions.
# Missing entries get 'Updating' as placeholder description.
# Safe to run multiple times — skips existing entries via LEFT JOIN.
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BMA_ROOT="$(dirname "$SCRIPT_DIR")"
DB_PROPS="$BMA_ROOT/servlets/servlet/src/main/webapp/WEB-INF/db.properties"

echo "═══════════════════════════════════════════════════════════════"
echo " Brarner.M.Alete™ — Populate Taxonomy Defaults"
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

# ─── MySQL helper ───
run_mysql() {
    mysql --user="$DB_USER" --password="$DB_PASS" --host="$DB_HOST" --port="$DB_PORT" --database="BrarnerScience" "$@" 2>/dev/null
}

# ─── Verify connectivity ───
echo "[*] Testing MySQL connection..."
if ! run_mysql -e "SELECT 1;" >/dev/null 2>&1; then
    echo "[!] Cannot connect to MySQL. Check db.properties."
    exit 1
fi
echo "[✓] MySQL connection OK"

# ─── Ensure table exists ───
echo "[*] Ensuring taxonomy_descriptions table exists..."
run_mysql << 'SQL'
CREATE TABLE IF NOT EXISTS taxonomy_descriptions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    rank_level ENUM('kingdom','phylum','class','order','family') NOT NULL,
    taxon_name VARCHAR(200) NOT NULL,
    description TEXT,
    characteristics TEXT,
    example_species VARCHAR(500),
    wikipedia_url VARCHAR(500),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_rank_taxon (rank_level, taxon_name),
    INDEX idx_rank (rank_level),
    INDEX idx_name (taxon_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
SQL

# ─── Ensure gbif_key column (MySQL 8.0 compatible) ───
HAS_GBIF_KEY=$(run_mysql -N -B -e "SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='BrarnerScience' AND TABLE_NAME='taxonomy_descriptions' AND COLUMN_NAME='gbif_key';")
if [ "$HAS_GBIF_KEY" = "0" ]; then
    echo "[*] Adding gbif_key column..."
    run_mysql -e "ALTER TABLE taxonomy_descriptions ADD COLUMN gbif_key INT;"
fi

# ─── Insert default 'Updating' for missing taxa ───
echo "[*] Inserting default descriptions for missing classes..."
CLASSES_BEFORE=$(run_mysql -N -B -e "SELECT COUNT(*) FROM taxonomy_descriptions WHERE rank_level='class';")
run_mysql << 'SQL'
INSERT INTO taxonomy_descriptions (rank_level, taxon_name, description)
SELECT 'class', a.class_name, 'Updating'
FROM (SELECT DISTINCT class_name FROM animalia WHERE class_name IS NOT NULL AND class_name!='') a
LEFT JOIN taxonomy_descriptions td ON td.rank_level='class' AND td.taxon_name=a.class_name
WHERE td.id IS NULL;
SQL
CLASSES_AFTER=$(run_mysql -N -B -e "SELECT COUNT(*) FROM taxonomy_descriptions WHERE rank_level='class';")
echo "    Classes: $((CLASSES_AFTER - CLASSES_BEFORE)) new defaults inserted (total: $CLASSES_AFTER)"

echo "[*] Inserting default descriptions for missing orders..."
ORDERS_BEFORE=$(run_mysql -N -B -e "SELECT COUNT(*) FROM taxonomy_descriptions WHERE rank_level='order';")
run_mysql << 'SQL'
INSERT INTO taxonomy_descriptions (rank_level, taxon_name, description)
SELECT 'order', a.order_name, 'Updating'
FROM (SELECT DISTINCT order_name FROM animalia WHERE order_name IS NOT NULL AND order_name!='') a
LEFT JOIN taxonomy_descriptions td ON td.rank_level='order' AND td.taxon_name=a.order_name
WHERE td.id IS NULL;
SQL
ORDERS_AFTER=$(run_mysql -N -B -e "SELECT COUNT(*) FROM taxonomy_descriptions WHERE rank_level='order';")
echo "    Orders: $((ORDERS_AFTER - ORDERS_BEFORE)) new defaults inserted (total: $ORDERS_AFTER)"

echo "[*] Inserting default descriptions for missing families..."
FAMILIES_BEFORE=$(run_mysql -N -B -e "SELECT COUNT(*) FROM taxonomy_descriptions WHERE rank_level='family';")
run_mysql << 'SQL'
INSERT INTO taxonomy_descriptions (rank_level, taxon_name, description)
SELECT 'family', a.family_name, 'Updating'
FROM (SELECT DISTINCT family_name FROM animalia WHERE family_name IS NOT NULL AND family_name!='') a
LEFT JOIN taxonomy_descriptions td ON td.rank_level='family' AND td.taxon_name=a.family_name
WHERE td.id IS NULL;
SQL
FAMILIES_AFTER=$(run_mysql -N -B -e "SELECT COUNT(*) FROM taxonomy_descriptions WHERE rank_level='family';")
echo "    Families: $((FAMILIES_AFTER - FAMILIES_BEFORE)) new defaults inserted (total: $FAMILIES_AFTER)"

# ─── Ensure kingdom entry ───
run_mysql << 'SQL'
INSERT IGNORE INTO taxonomy_descriptions (rank_level, taxon_name, description)
VALUES ('kingdom', 'Animalia', 'Updating');
SQL

# ─── Summary ───
echo ""
echo "═══════════════════════════════════════════════════════════════"
TOTAL=$(run_mysql -N -B -e "SELECT COUNT(*) FROM taxonomy_descriptions;")
UPDATING=$(run_mysql -N -B -e "SELECT COUNT(*) FROM taxonomy_descriptions WHERE description='Updating';")
POPULATED=$(run_mysql -N -B -e "SELECT COUNT(*) FROM taxonomy_descriptions WHERE description!='Updating';")
echo " [✓] Complete — $TOTAL total records"
echo ""
echo "     With descriptions: $POPULATED"
echo "     Awaiting update:   $UPDATING"
echo ""
run_mysql -N -B -e "SELECT CONCAT('     ', rank_level, ': ', COUNT(*), ' (', SUM(description='Updating'), ' updating)') FROM taxonomy_descriptions GROUP BY rank_level ORDER BY rank_level;"
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo " Next step: Run download-taxonomy-descriptions.sh to fetch"
echo " real descriptions from GBIF for 'Updating' entries."
echo "═══════════════════════════════════════════════════════════════"
