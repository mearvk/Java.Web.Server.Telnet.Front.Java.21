#!/usr/bin/env bash
# Brarner.M.Alete™ — Local Connectivity Test
# Tests the BMA servlet website on localhost (Tomcat)
# Usage: bash install/test-local.sh [port]
set -e

TOMCAT_PORT="${1:-8080}"
CONTEXT="brarner.m.alete"
BASE="http://localhost:${TOMCAT_PORT}/${CONTEXT}"

echo "═══════════════════════════════════════════════════════════════"
echo " Brarner.M.Alete™ — Local Connectivity Test"
echo " Base URL: ${BASE}"
echo "═══════════════════════════════════════════════════════════════"

PASS=0
FAIL=0

check() {
    local path="$1"
    local label="${2:-$path}"
    local url="${BASE}${path}"
    local status
    status=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$url" 2>/dev/null)
    if [ "$status" -ge 200 ] && [ "$status" -lt 400 ] 2>/dev/null; then
        echo "  [OK]   ${status}  ${label}"
        PASS=$((PASS + 1))
    else
        echo "  [FAIL] ${status}  ${label}"
        FAIL=$((FAIL + 1))
    fi
}

echo ""
echo "[*] Testing pages (JSP — preferred, server-side DB)..."
check "/" "Root (→ index.jsp welcome)"
check "/index.jsp" "index.jsp"
check "/species.jsp" "species.jsp"
check "/species.jsp?kingdom=Animalia" "species.jsp?kingdom=Animalia (DB query)"
check "/species.jsp?kingdom=Animalia&class=Mammalia" "species.jsp drill-down (class)"
check "/postal.jsp" "postal.jsp"
check "/art.jsp" "art.jsp"
check "/science.jsp" "science.jsp"
check "/status.jsp" "status.jsp (live DB check)"

echo ""
echo "[*] Testing pages (XHTML — legacy/reference)..."
check "/index.xhtml" "index.xhtml"
check "/species.xhtml" "species.xhtml"
check "/postal.xhtml" "postal.xhtml"
check "/art.xhtml" "art.xhtml"
check "/science.xhtml" "science.xhtml"
check "/status.xhtml" "status.xhtml"

echo ""
echo "[*] Testing admin pages..."
check "/admin/login.xhtml" "admin/login.xhtml"
check "/admin/dashboard.xhtml" "admin/dashboard.xhtml"
check "/admin/documents.xhtml" "admin/documents.xhtml"

echo ""
echo "[*] Testing static resources..."
check "/css/style.css" "css/style.css"
check "/config.xml" "config.xml"
check "/images/mearvk.ltd.logo.left.png" "logo-left"
check "/images/mearvk.ltd.logo.right.png" "logo-right"

echo ""
echo "[*] Checking db.properties..."
DB_PROPS="$( cd "$(dirname "$0")/.." && pwd )/servlets/servlet/src/main/webapp/WEB-INF/db.properties"
if [ -f "$DB_PROPS" ]; then
    echo "  [OK]   db.properties exists: $DB_PROPS"
    PASS=$((PASS + 1))
    DB_URL=$(grep '^db.url=' "$DB_PROPS" | cut -d= -f2-)
    DB_USER=$(grep '^db.user=' "$DB_PROPS" | cut -d= -f2-)
    echo "         url=$DB_URL  user=$DB_USER"
else
    echo "  [FAIL] db.properties NOT FOUND: $DB_PROPS"
    echo "         Run: bash install/install.sh to generate credentials"
    FAIL=$((FAIL + 1))
fi

echo ""
echo "[*] Testing MySQL connectivity..."
DB_HOST=$(echo "$DB_URL" 2>/dev/null | sed -n 's|.*://\([^:/]*\).*|\1|p')
DB_PORT=$(echo "$DB_URL" 2>/dev/null | sed -n 's|.*:\([0-9]*\)/.*|\1|p')
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-3306}"
if command -v mysql &>/dev/null && [ -f "$DB_PROPS" ]; then
    if mysql -u"$DB_USER" -p"$(grep '^db.password=' "$DB_PROPS" | cut -d= -f2-)" -h"$DB_HOST" -P"$DB_PORT" -e "SELECT 1" BrarnerScience &>/dev/null; then
        echo "  [OK]   MySQL BrarnerScience reachable (user=$DB_USER host=$DB_HOST:$DB_PORT)"
        PASS=$((PASS + 1))
    else
        echo "  [FAIL] MySQL connection failed (user=$DB_USER host=$DB_HOST:$DB_PORT)"
        FAIL=$((FAIL + 1))
    fi
elif timeout 3 bash -c "echo >/dev/tcp/${DB_HOST}/${DB_PORT}" 2>/dev/null; then
    echo "  [OK]   Port $DB_HOST:$DB_PORT open (mysql client not installed for full check)"
    PASS=$((PASS + 1))
else
    echo "  [FAIL] Cannot reach $DB_HOST:$DB_PORT"
    FAIL=$((FAIL + 1))
fi

echo ""
echo "[*] Testing JSP DB rendering (species.jsp should not contain 'undefined')..."
SPECIES_BODY=$(curl -s --max-time 5 "${BASE}/species.jsp?kingdom=Animalia" 2>/dev/null)
if echo "$SPECIES_BODY" | grep -qi "undefined"; then
    echo "  [FAIL] species.jsp contains 'undefined' — DB query may have failed"
    FAIL=$((FAIL + 1))
elif echo "$SPECIES_BODY" | grep -qi "Database error"; then
    echo "  [FAIL] species.jsp shows database error"
    FAIL=$((FAIL + 1))
else
    echo "  [OK]   species.jsp rendered without 'undefined' or DB error"
    PASS=$((PASS + 1))
fi

echo ""
echo "[*] Testing servlet endpoints..."
check "/api/status" "StatusApiServlet (/api/status)"
check "/api/species?level=class&kingdom=Animalia" "SpeciesApiServlet (class query)"
check "/admin/login" "AdminLoginServlet POST target (GET may 405)"

echo ""
echo "[*] Testing WEB-INF is protected..."
WEB_INF_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "${BASE}/WEB-INF/web.xml" 2>/dev/null)
if [ "$WEB_INF_STATUS" -ge 400 ] 2>/dev/null; then
    echo "  [OK]   ${WEB_INF_STATUS}  WEB-INF/web.xml (correctly blocked)"
    PASS=$((PASS + 1))
else
    echo "  [FAIL] ${WEB_INF_STATUS}  WEB-INF/web.xml (should be 403/404)"
    FAIL=$((FAIL + 1))
fi

echo ""
echo "───────────────────────────────────────────────────────────────"
echo " Results: ${PASS} passed | ${FAIL} failed"
echo "───────────────────────────────────────────────────────────────"

# Tomcat status
echo ""
echo "[*] Tomcat process:"
ps aux | grep -i "[t]omcat" || echo "  (not running)"
echo ""
echo "[*] Port ${TOMCAT_PORT} listeners:"
ss -tlnp 2>/dev/null | grep ":${TOMCAT_PORT}" || netstat -tlnp 2>/dev/null | grep ":${TOMCAT_PORT}" || echo "  (nothing on port ${TOMCAT_PORT})"
