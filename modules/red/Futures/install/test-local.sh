#!/usr/bin/env bash
# Futures — Local Connectivity & DB Test
# Usage: bash install/test-local.sh [port]
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MOD_ROOT="$(dirname "$SCRIPT_DIR")"
DB_PROPS="$MOD_ROOT/servlets/servlet/src/main/webapp/WEB-INF/db.properties"
TOMCAT_PORT="${1:-8080}"
CONTEXT="futures"
BASE="http://localhost:${TOMCAT_PORT}/${CONTEXT}"

echo "═══════════════════════════════════════════════════════════════"
echo " Futures — Local Connectivity & DB Test"
echo " Base URL: ${BASE}"
echo "═══════════════════════════════════════════════════════════════"

PASS=0; FAIL=0

check() {
    local path="$1" label="${2:-$1}"
    local status
    status=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "${BASE}${path}" 2>/dev/null)
    if [ "$status" -ge 200 ] && [ "$status" -lt 400 ] 2>/dev/null; then
        echo "  [OK]   ${status}  ${label}"; PASS=$((PASS + 1))
    else
        echo "  [FAIL] ${status}  ${label}"; FAIL=$((FAIL + 1))
    fi
}

echo ""
echo "[1] Page HTTP status checks..."
for jsp in index.jsp pipeline.jsp safety.jsp status.jsp training.jsp; do
    check "/${jsp}" "${jsp}"
done
check "/css/style.css" "css/style.css"

echo ""
echo "[2] Database rendering checks..."
check_db_page() {
    local page="$1" expect="$2" label="$3"
    local body
    body=$(curl -s --max-time 5 "${BASE}/${page}" 2>/dev/null)
    if echo "$body" | grep -qi "Database error"; then
        echo "  [FAIL] ${label}: DB ERROR — $(echo "$body" | grep -oP '(?<=Database error: )[^<]+' | head -1)"
        FAIL=$((FAIL + 1))
    elif echo "$body" | grep -qiE "$expect"; then
        echo "  [OK]   ${label}: data rendering ✓"; PASS=$((PASS + 1))
    else
        echo "  [WARN] ${label}: page rendered but expected content not found"; FAIL=$((FAIL + 1))
    fi
}
check_db_page "pipeline.jsp" "<td>|pipeline|stage|status" "pipeline.jsp"
check_db_page "training.jsp" "<td>|training|model|epoch" "training.jsp"
check_db_page "status.jsp"   "<td>|status|active|running" "status.jsp"

echo ""
echo "[3] db.properties diagnosis..."
if [ -f "$DB_PROPS" ]; then
    DB_USER=$(grep '^db.user=' "$DB_PROPS" | cut -d= -f2-)
    DB_PASS=$(grep '^db.password=' "$DB_PROPS" | cut -d= -f2-)
    DB_URL=$(grep '^db.url=' "$DB_PROPS" | cut -d= -f2-)
    DB_HOST=$(echo "$DB_URL" | sed -n 's|.*://\([^:/]*\).*|\1|p'); DB_HOST="${DB_HOST:-127.0.0.1}"
    DB_PORT=$(echo "$DB_URL" | sed -n 's|.*:\([0-9]*\)/.*|\1|p'); DB_PORT="${DB_PORT:-3306}"
    DB_NAME=$(echo "$DB_URL" | sed -n 's|.*/\([^?]*\).*|\1|p')
    echo "  Host: $DB_HOST:$DB_PORT  DB: $DB_NAME  User: $DB_USER"
    echo ""
    echo "[4] JDBC-equivalent connection test..."
    if mysql -u"$DB_USER" -p"$DB_PASS" -h"$DB_HOST" -P"$DB_PORT" "$DB_NAME" -e "SELECT 1" 2>/dev/null | grep -q 1; then
        echo "  [OK]   Connected to $DB_NAME"; PASS=$((PASS + 1))
        echo ""
        echo "[5] Table row counts..."
        TABLES=$(mysql -u"$DB_USER" -p"$DB_PASS" -h"$DB_HOST" -P"$DB_PORT" "$DB_NAME" -N -B -e "SHOW TABLES;" 2>/dev/null)
        for T in $TABLES; do
            COUNT=$(mysql -u"$DB_USER" -p"$DB_PASS" -h"$DB_HOST" -P"$DB_PORT" "$DB_NAME" -N -B -e "SELECT COUNT(*) FROM \`$T\`;" 2>/dev/null)
            [ "$COUNT" -gt 0 ] 2>/dev/null \
                && printf "  [OK]   %-20s %s rows\n" "$T" "$COUNT" \
                || printf "  [EMPTY] %-20s 0 rows\n" "$T"
        done
    else
        echo "  [FAIL] Cannot connect as $DB_USER@$DB_HOST:$DB_PORT to $DB_NAME"; FAIL=$((FAIL + 1))
        systemctl is-active mysql &>/dev/null && echo "  [OK]   MySQL service running" || echo "  [FAIL] MySQL service NOT running — sudo systemctl start mysql"
    fi
else
    echo "  [FAIL] db.properties NOT FOUND: $DB_PROPS"; FAIL=$((FAIL + 1))
fi

echo ""
echo "───────────────────────────────────────────────────────────────"
echo " Results: ${PASS} passed | ${FAIL} failed"
echo "═══════════════════════════════════════════════════════════════"
