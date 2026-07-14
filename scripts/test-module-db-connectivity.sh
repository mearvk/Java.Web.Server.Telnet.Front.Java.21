#!/bin/bash
# NitroWebExpress™ — Test Module Database Connectivity
# Usage: bash scripts/test-module-db-connectivity.sh
set -uo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0

ok()   { echo "  [PASS] $1"; PASS=$((PASS + 1)); }
fail() { echo "  [FAIL] $1"; FAIL=$((FAIL + 1)); }

echo "── Module Database Connectivity ──"

if ! command -v mysql &>/dev/null; then fail "mysql client not on PATH"; exit 1; fi

# Determine working MySQL credentials (try password, then no password)
MY=""
if mysqladmin ping -u root --password='$$Ironman1' --silent 2>/dev/null; then
    MY="mysql -u root --password=\$\$Ironman1 --silent --skip-column-names"
elif mysqladmin ping -u root --silent 2>/dev/null; then
    MY="mysql -u root --silent --skip-column-names"
else
    fail "MySQL server not responding"; exit 1
fi
ok "MySQL server responding"

# All module databases
declare -A DATABASES=(
    [BrarnerScience]="(any)" [nwe_ae6e66]="contacts" [nwe_strernary]="(any)"
    [nwe_futures]="(any)" [nwe_gdgh]="(any)"
    [nwe_gray_registry]="(any)" [nwe_gray85_registry]="(any)"
    [nwe_california_fbi]="crime_reports" [nwe_california_cia]="intelligence_reports"
    [nwe_california_nsa]="cyber_reports" [nwe_duke]="college_queries"
    [nwe_library]="library_requests"
    [nwe_japan]="(any)" [nwe_russia]="(any)" [nwe_mexico]="(any)" [nwe_greece_intl]="(any)"
)

for DB in "${!DATABASES[@]}"; do
    TABLE="${DATABASES[$DB]}"
    EXISTS=$($MY -e "SELECT SCHEMA_NAME FROM information_schema.SCHEMATA WHERE SCHEMA_NAME='$DB'" 2>/dev/null)
    if [ -z "$EXISTS" ]; then fail "$DB — database does not exist"; continue; fi
    RESULT=$($MY -e "USE $DB; SELECT 1;" 2>/dev/null)
    if [ "$RESULT" != "1" ]; then fail "$DB — cannot query"; continue; fi
    if [[ "$TABLE" != "(any)" ]]; then
        TBL=$($MY -e "SELECT TABLE_NAME FROM information_schema.TABLES WHERE TABLE_SCHEMA='$DB' AND TABLE_NAME='$TABLE'" 2>/dev/null)
        if [ -z "$TBL" ]; then fail "$DB — table '$TABLE' missing"; continue; fi
        ROWS=$($MY -e "SELECT COUNT(*) FROM $DB.$TABLE" 2>/dev/null)
        ok "$DB.$TABLE — connected ($ROWS rows)"
    else
        CNT=$($MY -e "SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA='$DB'" 2>/dev/null)
        ok "$DB — connected ($CNT tables)"
    fi
done

# db.properties verification
echo ""
echo "── db.properties Verification ──"
DB_PROPS=(
    "modules/AE6E66/servlets/servlet/src/main/webapp/WEB-INF/db.properties"
    "modules/fbi/servlets/servlet/src/main/webapp/WEB-INF/db.properties"
    "modules/cia/servlets/servlet/src/main/webapp/WEB-INF/db.properties"
    "modules/nsa/servlets/servlet/src/main/webapp/WEB-INF/db.properties"
    "modules/duke/servlets/servlet/src/main/webapp/WEB-INF/db.properties"
    "modules/library/servlets/servlet/src/main/webapp/WEB-INF/db.properties"
)
for PROP in "${DB_PROPS[@]}"; do
    FULL="$PROJECT_ROOT/$PROP"
    if [ ! -f "$FULL" ]; then fail "$PROP — file missing"; continue; fi
    DB_URL=$(grep "db.url" "$FULL" | cut -d= -f2-)
    DB_NAME=$(echo "$DB_URL" | grep -oP '[^/]+$')
    DB_USER=$(grep "db.user" "$FULL" | cut -d= -f2-)
    DB_PASS=$(grep "db.password" "$FULL" | cut -d= -f2-)
    # Use the credentials from the properties file itself
    CONN=$(mysql -u "$DB_USER" --password="$DB_PASS" --silent --skip-column-names -e "USE $DB_NAME; SELECT 1;" 2>/dev/null)
    if [ "$CONN" == "1" ]; then
        ok "$PROP → $DB_NAME (user=$DB_USER)"
    else
        fail "$PROP → $DB_NAME — connection failed (user=$DB_USER)"
    fi
done

# Installer ID Tech™
echo ""
echo "── Installer ID Tech™ Column Verification ──"
INSTALLER_TABLES=(
    "nwe_california_fbi:crime_reports" "nwe_california_fbi:fbi_forwarded_tips"
    "nwe_california_cia:intelligence_reports" "nwe_california_cia:foia_requests"
    "nwe_california_nsa:cyber_reports" "nwe_california_nsa:advisories"
    "nwe_duke:college_queries" "nwe_duke:course_catalog"
    "nwe_library:library_requests" "nwe_library:catalog_cache"
)
for ENTRY in "${INSTALLER_TABLES[@]}"; do
    DB="${ENTRY%%:*}"; TBL="${ENTRY##*:}"
    COL=$($MY -e "SELECT COLUMN_NAME FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='$DB' AND TABLE_NAME='$TBL' AND COLUMN_NAME='installer_id'" 2>/dev/null)
    if [ -n "$COL" ]; then ok "$DB.$TBL — installer_id present"
    else
        TBL_CHK=$($MY -e "SELECT TABLE_NAME FROM information_schema.TABLES WHERE TABLE_SCHEMA='$DB' AND TABLE_NAME='$TBL'" 2>/dev/null)
        [ -z "$TBL_CHK" ] && fail "$DB.$TBL — table missing" || fail "$DB.$TBL — installer_id MISSING"
    fi
done

echo ""
echo "── DB Test Summary: $PASS passed | $FAIL failed ──"
[[ $FAIL -gt 0 ]] && exit 1 || exit 0
