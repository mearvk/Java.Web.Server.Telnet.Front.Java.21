#!/usr/bin/env bash
# Brarner.M.Alete™ — Local Connectivity Test
# Tests the BMA servlet website on localhost (Tomcat)
# Usage: bash install/test-local.sh

TOMCAT_PORT="${1:-8080}"
BASE="http://localhost:${TOMCAT_PORT}/brarner"

echo "═══════════════════════════════════════════════════════════════"
echo " Brarner.M.Alete™ — Local Connectivity Test"
echo " Base URL: ${BASE}"
echo "═══════════════════════════════════════════════════════════════"

PASS=0
FAIL=0

check() {
    local path="$1"
    local url="${BASE}${path}"
    local status
    status=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$url" 2>/dev/null)
    if [ "$status" -ge 200 ] && [ "$status" -lt 400 ] 2>/dev/null; then
        echo "  [OK]   ${status}  ${url}"
        PASS=$((PASS + 1))
    else
        echo "  [FAIL] ${status}  ${url}"
        FAIL=$((FAIL + 1))
    fi
}

echo ""
echo "[*] Testing known pages..."
echo ""

# Root / index
check "/"
check "/index.html"
check "/index.jsp"

# Tabs from BMA website
check "/overview"
check "/species"
check "/postal"
check "/art"
check "/science"
check "/status"

# Static resources
check "/images/logo/mearvk.ltd.logo.png"
check "/WEB-INF/web.xml"

# Servlet endpoints
check "/servlet/status"
check "/servlet/species"
check "/servlet/postal"

echo ""
echo "───────────────────────────────────────────────────────────────"
echo " Results: ${PASS} passed | ${FAIL} failed"
echo "───────────────────────────────────────────────────────────────"

# Tomcat status
echo ""
echo "[*] Tomcat process:"
ps aux | grep -i tomcat | grep -v grep || echo "  (not running)"
echo ""
echo "[*] Port ${TOMCAT_PORT} listeners:"
ss -tlnp | grep ":${TOMCAT_PORT}" || echo "  (nothing on port ${TOMCAT_PORT})"
