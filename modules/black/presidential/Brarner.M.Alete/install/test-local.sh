#!/usr/bin/env bash
# Brarner.M.Alete™ — Local Connectivity & DB Test
# Tests pages, checks DB rendering, diagnoses connection issues
# Usage: bash install/test-local.sh [port]
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BMA_ROOT="$(dirname "$SCRIPT_DIR")"
DB_PROPS="$BMA_ROOT/servlets/servlet/src/main/webapp/WEB-INF/db.properties"

TOMCAT_PORT="${1:-8080}"
CONTEXT="brarner.m.alete"
BASE="http://localhost:${TOMCAT_PORT}/${CONTEXT}"

echo "═══════════════════════════════════════════════════════════════"
echo " Brarner.M.Alete™ — Local Connectivity & DB Test"
echo " Base URL: ${BASE}"
echo "═══════════════════════════════════════════════════════════════"

PASS=0; FAIL=0

check() {
    local path="$1" label="${2:-$1}"
    local status
    status=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "${BASE}${path}" 2>/dev/null)
    if [ "$status" -ge 200 ] && [ "$status" -lt 400 ] 2>/dev/null; then
        echo "  [OK]   ${status}  ${label}"
        PASS=$((PASS + 1))
    else
        echo "  [FAIL] ${status}  ${label}"
        FAIL=$((FAIL + 1))
    fi
}

echo ""
echo "[1] Page HTTP status checks..."
WEBAPP_DIR="$BMA_ROOT/servlets/servlet/src/main/webapp"
for jsp in $(find "$WEBAPP_DIR" -maxdepth 1 -name "*.jsp" -printf "%f\n" 2>/dev/null | sort); do
    check "/${jsp}" "${jsp}"
done
check "/css/style.css" "css/style.css"

echo ""
echo "[2] Database rendering checks (do pages show data?)..."

# Check each page for DB errors or actual content
check_db_page() {
    local page="$1" expect="$2" label="$3"
    local body
    body=$(curl -s --max-time 5 "${BASE}/${page}" 2>/dev/null)

    if echo "$body" | grep -qi "Database error"; then
        local err=$(echo "$body" | grep -oP '(?<=Database error: )[^<]+' | head -1)
        local diag=$(echo "$body" | grep -oP '(?<=User: )[^<]+' | head -1)
        echo "  [FAIL] ${label}: DB ERROR"
        echo "         Error: $err"
        [ -n "$diag" ] && echo "         Diag:  $diag"
        FAIL=$((FAIL + 1))
        return 1
    elif echo "$body" | grep -qiE "$expect"; then
        echo "  [OK]   ${label}: data rendering ✓"
        PASS=$((PASS + 1))
        return 0
    elif echo "$body" | grep -qiE "No .* available|No records found"; then
        echo "  [WARN] ${label}: page works but table is EMPTY"
        echo "         Run: bash install/populate-all.sh"
        FAIL=$((FAIL + 1))
        return 1
    else
        echo "  [WARN] ${label}: page rendered but expected content not found"
        FAIL=$((FAIL + 1))
        return 1
    fi
}

check_db_page "postal.jsp" "NC|zip_code|Durham|Raleigh" "postal.jsp (states)"
check_db_page "art.jsp" "Museum|museum_name|Monet|Ackland" "art.jsp (museums)"
check_db_page "science.jsp" "Nature|source_name|Science|PNAS" "science.jsp (sources)"
check_db_page "species.jsp?kingdom=Animalia" "Amphibia|Mammalia|Animalia|<td>" "species.jsp (animalia)"

echo ""
echo "[3] db.properties diagnosis..."
if [ -f "$DB_PROPS" ]; then
    DB_USER=$(grep '^db.user=' "$DB_PROPS" | cut -d= -f2-)
    DB_URL=$(grep '^db.url=' "$DB_PROPS" | cut -d= -f2-)
    DB_HOST=$(echo "$DB_URL" | sed -n 's|.*://\([^:/]*\).*|\1|p')
    DB_PORT=$(echo "$DB_URL" | sed -n 's|.*:\([0-9]*\)/.*|\1|p')
    DB_NAME=$(echo "$DB_URL" | sed -n 's|.*/\([^?]*\).*|\1|p')
    DB_PASS=$(grep '^db.password=' "$DB_PROPS" | cut -d= -f2-)
    DB_HOST="${DB_HOST:-localhost}"
    DB_PORT="${DB_PORT:-3306}"

    echo "  File:     $DB_PROPS"
    echo "  User:     $DB_USER"
    echo "  Host:     $DB_HOST:$DB_PORT"
    echo "  Database: $DB_NAME"
    echo "  Password: $([ -n "$DB_PASS" ] && echo "set (${#DB_PASS} chars)" || echo "EMPTY!")"
    echo ""

    # Test the same connection the JSP would make
    echo "[4] Testing JDBC-equivalent connection (same as JSP pages)..."
    if mysql -u"$DB_USER" -p"$DB_PASS" -h"$DB_HOST" -P"$DB_PORT" "$DB_NAME" -e "SELECT 1" 2>/dev/null | grep -q 1; then
        echo "  [OK]   mysql -u$DB_USER -h$DB_HOST -P$DB_PORT $DB_NAME → connected"
        PASS=$((PASS + 1))

        # Check tables have data
        echo ""
        echo "[5] Table row counts (same DB the JSP queries)..."
        TABLES=$(mysql -u"$DB_USER" -p"$DB_PASS" -h"$DB_HOST" -P"$DB_PORT" "$DB_NAME" -N -B -e "SHOW TABLES;" 2>/dev/null)
        for T in $TABLES; do
            COUNT=$(mysql -u"$DB_USER" -p"$DB_PASS" -h"$DB_HOST" -P"$DB_PORT" "$DB_NAME" -N -B -e "SELECT COUNT(*) FROM \`$T\`;" 2>/dev/null)
            if [ "$COUNT" -gt 0 ] 2>/dev/null; then
                printf "  [OK]   %-20s %s rows\n" "$T" "$COUNT"
            else
                printf "  [EMPTY] %-20s 0 rows — run populate script\n" "$T"
            fi
        done
    else
        echo "  [FAIL] Cannot connect as $DB_USER@$DB_HOST:$DB_PORT to $DB_NAME"
        FAIL=$((FAIL + 1))
        echo ""
        echo "  Troubleshooting:"
        echo "  ─────────────────────────────────────────────────────"

        # Check if MySQL is running
        if systemctl is-active mysql &>/dev/null || systemctl is-active mysqld &>/dev/null || systemctl is-active mariadb &>/dev/null; then
            echo "  [OK]   MySQL service is running"
        else
            echo "  [FAIL] MySQL service is NOT running"
            echo "         Fix: sudo systemctl start mysql"
        fi

        # Check if port is open
        if timeout 2 bash -c "echo >/dev/tcp/$DB_HOST/$DB_PORT" 2>/dev/null; then
            echo "  [OK]   Port $DB_HOST:$DB_PORT is open"
        else
            echo "  [FAIL] Port $DB_HOST:$DB_PORT not reachable"
            echo "         Fix: check bind-address in /etc/mysql/mysql.conf.d/mysqld.cnf"
        fi

        # Check if user exists
        if sudo mysql -e "SELECT User,Host,plugin FROM mysql.user WHERE User='$DB_USER'" 2>/dev/null; then
            echo ""
            echo "  If plugin=auth_socket, JDBC cannot use this user."
            echo "  Fix: sudo bash install/create-db-user.sh"
        fi

        # Check localhost vs 127.0.0.1
        if [ "$DB_HOST" = "localhost" ]; then
            echo ""
            echo "  [HINT] db.url uses 'localhost' which may use unix_socket auth."
            echo "         Change to 127.0.0.1 in db.properties to force TCP:"
            echo "         db.url=jdbc:mysql://127.0.0.1:3306/$DB_NAME"
        fi

        echo ""
        echo "  Quick fix: sudo bash install/create-db-user.sh"
        echo "  ─────────────────────────────────────────────────────"
    fi
else
    echo "  [FAIL] db.properties NOT FOUND: $DB_PROPS"
    echo "         Run: bash install/set-db-credentials.sh"
    FAIL=$((FAIL + 1))
fi

echo ""
echo "───────────────────────────────────────────────────────────────"
echo " Results: ${PASS} passed | ${FAIL} failed"
echo "═══════════════════════════════════════════════════════════════"
