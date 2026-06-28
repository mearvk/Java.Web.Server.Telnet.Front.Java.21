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
