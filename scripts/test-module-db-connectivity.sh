#!/bin/bash
# NitroWebExpress™ — Test Module Database Connectivity
# Checks MySQL connectivity for every module database.
# Usage: bash scripts/test-module-db-connectivity.sh
set -uo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0

ok()   { echo "  [PASS] $1"; PASS=$((PASS + 1)); }
fail() { echo "  [FAIL] $1"; FAIL=$((FAIL + 1)); }

echo "── Module Database Connectivity ──"

# Check MySQL is running
if ! command -v mysql &>/dev/null; then
    echo "  [FAIL] mysql client not found on PATH"
    exit 1
fi

if ! mysqladmin ping -u root --password='$$Ironman1' --silent 2>/dev/null; then
    if ! mysqladmin ping -u root --silent 2>/dev/null; then
        echo "  [FAIL] MySQL server not responding"
        exit 1
    fi
fi
ok "MySQL server responding"

# Database list with expected tables
declare -A DATABASES=(
    [BrarnerScience]="(any)"
    [nwe_ae6e66]="contacts"
    [nwe_futures]="(any)"
    [nwe_gdgh]="(any)"
    [nwe_gray_registry]="(any)"
    [nwe_gray85_registry]="(any)"
    [nwe_strernary]="(any)"
    [nwe_california_fbi]="crime_reports"
    [nwe_california_cia]="intelligence_reports"
    [nwe_california_nsa]="cyber_reports"
    [nwe_duke]="college_queries"
    [nwe_library]="library_requests"
    [nwe_japan]="(any)"
    [nwe_russia]="(any)"
    [nwe_mexico]="(any)"
    [nwe_greece_intl]="(any)"
)

MYSQL_OPTS="-u root --password=\$\$Ironman1 --silent --skip-column-names"

for DB in "${!DATABASES[@]}"; do
    TABLE="${DATABASES[$DB]}"

    # Check database exists
    EXISTS=$(mysql $MYSQL_OPTS -e "SELECT SCHEMA_NAME FROM information_schema.SCHEMATA WHERE SCHEMA_NAME='$DB'" 2>/dev/null)
    if [ -z "$EXISTS" ]; then
        fail "$DB — database does not exist"
        continue
    fi

    # Check connectivity (run a simple query)
    RESULT=$(mysql $MYSQL_OPTS -e "USE $DB; SELECT 1;" 2>/dev/null)
    if [ "$RESULT" != "1" ]; then
        fail "$DB — cannot connect/query"
        continue
    fi

    # Check specific table if not (any)
    if [[ "$TABLE" != "(any)" ]]; then
        TBL_EXISTS=$(mysql $MYSQL_OPTS -e "SELECT TABLE_NAME FROM information_schema.TABLES WHERE TABLE_SCHEMA='$DB' AND TABLE_NAME='$TABLE'" 2>/dev/null)
        if [ -z "$TBL_EXISTS" ]; then
            fail "$DB — table '$TABLE' missing (run setup-db.sh)"
            continue
        fi
        ROW_COUNT=$(mysql $MYSQL_OPTS -e "SELECT COUNT(*) FROM $DB.$TABLE" 2>/dev/null)
        ok "$DB.$TABLE — connected ($ROW_COUNT rows)"
    else
        TBL_COUNT=$(mysql $MYSQL_OPTS -e "SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA='$DB'" 2>/dev/null)
        ok "$DB — connected ($TBL_COUNT tables)"
    fi
done

# ── Check db.properties files match actual databases ──────────────────────────
echo ""
echo "── db.properties Verification ──"

DB_PROPS_FILES=(
    "modules/AE6E66/servlets/servlet/src/main/webapp/WEB-INF/db.properties"
    "california/fbi/servlets/servlet/src/main/webapp/WEB-INF/db.properties"
    "california/cia/servlets/servlet/src/main/webapp/WEB-INF/db.properties"
    "california/nsa/servlets/servlet/src/main/webapp/WEB-INF/db.properties"
    "north/carolina/duke/servlets/servlet/src/main/webapp/WEB-INF/db.properties"
    "north/carolina/library/servlets/servlet/src/main/webapp/WEB-INF/db.properties"
)

for PROP_FILE in "${DB_PROPS_FILES[@]}"; do
    FULL="$PROJECT_ROOT/$PROP_FILE"
    if [ ! -f "$FULL" ]; then
        fail "$PROP_FILE — file missing"
        continue
    fi

    DB_URL=$(grep "db.url" "$FULL" | cut -d= -f2-)
    DB_NAME=$(echo "$DB_URL" | grep -oP '[^/]+$')
    DB_USER=$(grep "db.user" "$FULL" | cut -d= -f2-)

    if [ -z "$DB_NAME" ]; then
        fail "$PROP_FILE — cannot parse db.url"
        continue
    fi

    # Test actual JDBC-style connectivity
    CONN_TEST=$(mysql -u "$DB_USER" --password='$$Ironman1' -e "USE $DB_NAME; SELECT 1;" --silent --skip-column-names 2>/dev/null)
    if [ "$CONN_TEST" == "1" ]; then
        ok "$PROP_FILE → $DB_NAME (user=$DB_USER)"
    else
        fail "$PROP_FILE → $DB_NAME — connection failed (user=$DB_USER)"
    fi
done

# ── Installer ID Tech™ column check ──────────────────────────────────────────
echo ""
echo "── Installer ID Tech™ Column Verification ──"

INSTALLER_TABLES=(
    "nwe_california_fbi:crime_reports"
    "nwe_california_fbi:fbi_forwarded_tips"
    "nwe_california_cia:intelligence_reports"
    "nwe_california_cia:foia_requests"
    "nwe_california_nsa:cyber_reports"
    "nwe_california_nsa:advisories"
    "nwe_duke:college_queries"
    "nwe_duke:course_catalog"
    "nwe_library:library_requests"
    "nwe_library:catalog_cache"
)

for ENTRY in "${INSTALLER_TABLES[@]}"; do
    DB="${ENTRY%%:*}"
    TBL="${ENTRY##*:}"
    COL_EXISTS=$(mysql $MYSQL_OPTS -e "SELECT COLUMN_NAME FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='$DB' AND TABLE_NAME='$TBL' AND COLUMN_NAME='installer_id'" 2>/dev/null)
    if [ -n "$COL_EXISTS" ]; then
        ok "$DB.$TBL — installer_id column present"
    else
        # Table might not exist yet
        TBL_CHECK=$(mysql $MYSQL_OPTS -e "SELECT TABLE_NAME FROM information_schema.TABLES WHERE TABLE_SCHEMA='$DB' AND TABLE_NAME='$TBL'" 2>/dev/null)
        if [ -z "$TBL_CHECK" ]; then
            fail "$DB.$TBL — table does not exist (run setup-db.sh)"
        else
            fail "$DB.$TBL — installer_id column MISSING (Installer ID Tech™ not applied)"
        fi
    fi
done

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "── DB Test Summary: $PASS passed | $FAIL failed ──"
[[ $FAIL -gt 0 ]] && exit 1 || exit 0
