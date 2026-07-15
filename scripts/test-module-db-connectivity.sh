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

# ── Credential Resolution ─────────────────────────────────────────────────────
# Priority: .nwe-credentials → environment → prompt
NWE_DB_USER="${NWE_DB_USER:-}"
NWE_DB_PASS="${NWE_DB_PASS:-}"

if [ -f "$PROJECT_ROOT/.nwe-credentials" ]; then
    source "$PROJECT_ROOT/.nwe-credentials"
    echo "  [*] Loaded credentials from .nwe-credentials"
fi

# Validate credentials actually work
DB_VALIDATED=false
if [ -n "$NWE_DB_PASS" ]; then
    if mysqladmin ping -u "${NWE_DB_USER:-root}" --password="${NWE_DB_PASS}" --silent 2>/dev/null; then
        MY="mysql -u ${NWE_DB_USER:-root} --password=${NWE_DB_PASS} --silent --skip-column-names"
        DB_VALIDATED=true
        ok "MySQL credentials validated (user=${NWE_DB_USER:-root})"
    else
        fail "MySQL credentials in .nwe-credentials are INVALID"
        echo ""
        echo "  ┌────────────────────────────────────────────────────────────────────"
        echo "  │ The password in .nwe-credentials does not work against MySQL."
        echo "  │"
        echo "  │ This can happen when:"
        echo "  │   • MySQL password was changed after initial setup"
        echo "  │   • A different MySQL user is configured on this server"
        echo "  │   • MySQL is using a different auth plugin"
        echo "  │"
        echo "  │ FIX: Edit .nwe-credentials with the correct password:"
        echo "  │      nano $PROJECT_ROOT/.nwe-credentials"
        echo "  │"
        echo "  │ Or reset the MySQL password:"
        echo "  │      sudo mysql -e \"ALTER USER 'root'@'localhost' IDENTIFIED BY 'new_password';\""
        echo "  └────────────────────────────────────────────────────────────────────"
        echo ""
    fi
fi

# Fallback: try passwordless root (some dev setups)
if [ "$DB_VALIDATED" = false ]; then
    if mysqladmin ping -u root --silent 2>/dev/null; then
        MY="mysql -u root --silent --skip-column-names"
        DB_VALIDATED=true
        warn "Using passwordless MySQL root (set a password for production!)"
    fi
fi

# Last resort: prompt
if [ "$DB_VALIDATED" = false ] && [ -t 0 ]; then
    echo ""
    echo "  [?] MySQL credentials not working. Enter manually:"
    read -rp "      MySQL user [root]: " PROMPT_USER
    PROMPT_USER="${PROMPT_USER:-root}"
    read -rsp "      MySQL password: " PROMPT_PASS
    echo ""
    if mysqladmin ping -u "$PROMPT_USER" --password="$PROMPT_PASS" --silent 2>/dev/null; then
        MY="mysql -u $PROMPT_USER --password=$PROMPT_PASS --silent --skip-column-names"
        DB_VALIDATED=true
        ok "MySQL credentials validated (manual entry)"
        echo ""
        echo "  [*] TIP: Save these credentials for future runs:"
        echo "      echo \"NWE_DB_USER='$PROMPT_USER'\" > $PROJECT_ROOT/.nwe-credentials"
        echo "      echo \"NWE_DB_PASS='...'\" >> $PROJECT_ROOT/.nwe-credentials"
        echo "      chmod 600 $PROJECT_ROOT/.nwe-credentials"
        echo ""
    else
        fail "Manual credentials also failed"
    fi
fi

if [ "$DB_VALIDATED" = false ]; then
    fail "Cannot connect to MySQL — all credential methods exhausted"
    echo ""
    echo "  ── DB Test Summary: $PASS passed | $FAIL failed ──"
    exit 1
fi

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
DB_PROPS_FAILED=0
for PROP in "${DB_PROPS[@]}"; do
    FULL="$PROJECT_ROOT/$PROP"
    if [ ! -f "$FULL" ]; then
        fail "$PROP — file missing (run deploy to generate from .nwe-credentials)"
        DB_PROPS_FAILED=$((DB_PROPS_FAILED + 1))
        continue
    fi
    # Check for placeholder passwords
    if grep -q "CHANGE_ME" "$FULL" 2>/dev/null; then
        fail "$PROP — contains CHANGE_ME placeholder (update .nwe-credentials and redeploy)"
        DB_PROPS_FAILED=$((DB_PROPS_FAILED + 1))
        continue
    fi
    DB_URL=$(grep "db.url" "$FULL" | cut -d= -f2-)
    DB_NAME=$(echo "$DB_URL" | grep -oP '[^/]+$')
    DB_USER=$(grep "db.user" "$FULL" | cut -d= -f2-)
    DB_PASS_LOCAL=$(grep "db.password" "$FULL" | cut -d= -f2-)
    # Test actual connectivity with the stored credentials
    CONN=$(mysql -u "$DB_USER" --password="$DB_PASS_LOCAL" --silent --skip-column-names -e "USE $DB_NAME; SELECT 1;" 2>/dev/null)
    if [ "$CONN" == "1" ]; then
        ok "$PROP → $DB_NAME (user=$DB_USER)"
    else
        fail "$PROP → $DB_NAME — connection FAILED (user=$DB_USER)"
        DB_PROPS_FAILED=$((DB_PROPS_FAILED + 1))
    fi
done

if [ $DB_PROPS_FAILED -gt 0 ]; then
    echo ""
    echo "  ┌────────────────────────────────────────────────────────────────────"
    echo "  │ $DB_PROPS_FAILED db.properties file(s) have invalid credentials."
    echo "  │"
    echo "  │ FIX: Update .nwe-credentials with the correct MySQL password,"
    echo "  │ then redeploy the affected modules:"
    echo "  │"
    echo "  │   nano $PROJECT_ROOT/.nwe-credentials"
    echo "  │   bash scripts/start-frontends.sh    (re-deploys missing)"
    echo "  │   — OR manually per module: —"
    echo "  │   bash modules/<name>/servlets/deploy-local.sh"
    echo "  │"
    echo "  │ The deploy scripts auto-generate db.properties from .nwe-credentials."
    echo "  └────────────────────────────────────────────────────────────────────"
    echo ""
fi

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
