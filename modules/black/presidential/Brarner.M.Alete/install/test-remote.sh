#!/usr/bin/env bash
# Brarner.M.Alete™ — Remote Connectivity Test
# Tests the BMA website on the remote server via HTTPS
# Usage: bash install/test-remote.sh [domain]
set -e

DOMAIN="${1:-lauradei.us}"
CONTEXT="brarner.m.alete"
BASE_HTTP="http://${DOMAIN}/${CONTEXT}"
BASE_HTTPS="https://${DOMAIN}/${CONTEXT}"

echo "═══════════════════════════════════════════════════════════════"
echo " Brarner.M.Alete™ — Remote Connectivity Test"
echo " Domain: ${DOMAIN}"
echo " HTTP:   ${BASE_HTTP}"
echo " HTTPS:  ${BASE_HTTPS}"
echo "═══════════════════════════════════════════════════════════════"

PASS=0
FAIL=0
REDIRECT=0

check() {
    local url="$1"
    local label="$2"
    local status
    status=$(curl -s -o /dev/null -w "%{http_code}" --max-time 15 --connect-timeout 10 "$url" 2>/dev/null)
    if [ "$status" -ge 200 ] && [ "$status" -lt 300 ] 2>/dev/null; then
        echo "  [OK]       ${status}  ${label}"
        PASS=$((PASS + 1))
    elif [ "$status" -ge 300 ] && [ "$status" -lt 400 ] 2>/dev/null; then
        echo "  [REDIRECT] ${status}  ${label}"
        REDIRECT=$((REDIRECT + 1))
    elif [ "$status" = "000" ]; then
        echo "  [NOCONN]   ---  ${label}  (connection failed/timeout)"
        FAIL=$((FAIL + 1))
    else
        echo "  [FAIL]     ${status}  ${label}"
        FAIL=$((FAIL + 1))
    fi
}

echo ""
echo "[*] DNS Resolution..."
IP=$(dig +short "$DOMAIN" 2>/dev/null | head -1 || host "$DOMAIN" 2>/dev/null | awk '/address/{print $NF}' | head -1)
echo "  ${DOMAIN} → ${IP:-UNRESOLVED}"
if [ -z "$IP" ]; then
    echo "  [!] DNS not resolving — cannot proceed"
    exit 1
fi

echo ""
echo "[*] Port check..."
for port in 80 443; do
    if timeout 5 bash -c "echo >/dev/tcp/${IP}/${port}" 2>/dev/null; then
        echo "  [OK]   Port ${port} open"
    else
        echo "  [FAIL] Port ${port} closed/unreachable"
    fi
done

echo ""
echo "[*] SSL Certificate..."
CERT_INFO=$(echo | openssl s_client -connect "${DOMAIN}:443" -servername "$DOMAIN" 2>/dev/null | openssl x509 -noout -subject -issuer -dates 2>/dev/null)
if [ -n "$CERT_INFO" ]; then
    echo "$CERT_INFO" | sed 's/^/  /'
else
    echo "  [!] No valid SSL cert found"
fi

echo ""
echo "[*] HTTP → HTTPS redirect..."
check "$BASE_HTTP/" "HTTP root (expect 301→HTTPS)"

echo ""
echo "[*] HTTPS pages (JSP — preferred, server-side DB)..."
SCRIPT_DIR_REAL="$(cd "$(dirname "$0")" && pwd)"
WEBAPP_DIR="$(dirname "$SCRIPT_DIR_REAL")/servlets/servlet/src/main/webapp"
for jsp in $(find "$WEBAPP_DIR" -maxdepth 1 -name "*.jsp" -printf "%f\n" 2>/dev/null | sort); do
    check "$BASE_HTTPS/${jsp}" "${jsp}"
done
check "$BASE_HTTPS/species.jsp?kingdom=Animalia" "species.jsp?kingdom=Animalia (DB query)"
check "$BASE_HTTPS/species.jsp?kingdom=Animalia&class=Mammalia" "species.jsp drill-down (class)"

echo ""
echo "[*] HTTPS pages (XHTML — legacy/reference)..."
check "$BASE_HTTPS/index.xhtml" "index.xhtml"
check "$BASE_HTTPS/species.xhtml" "species.xhtml"
check "$BASE_HTTPS/postal.xhtml" "postal.xhtml"
check "$BASE_HTTPS/art.xhtml" "art.xhtml"
check "$BASE_HTTPS/science.xhtml" "science.xhtml"
check "$BASE_HTTPS/status.xhtml" "status.xhtml"

echo ""
echo "[*] Admin pages..."
check "$BASE_HTTPS/admin/login.xhtml" "admin/login.xhtml"
check "$BASE_HTTPS/admin/dashboard.xhtml" "admin/dashboard.xhtml"
check "$BASE_HTTPS/admin/documents.xhtml" "admin/documents.xhtml"

echo ""
echo "[*] Static resources..."
check "$BASE_HTTPS/css/style.css" "css/style.css"
check "$BASE_HTTPS/config.xml" "config.xml"
check "$BASE_HTTPS/images/mearvk.ltd.logo.left.png" "logo-left"
check "$BASE_HTTPS/images/mearvk.ltd.logo.right.png" "logo-right"

echo ""
echo "[*] Checking db.properties (local copy)..."
DB_PROPS="$( cd "$(dirname "$0")/.." && pwd )/servlets/servlet/src/main/webapp/WEB-INF/db.properties"
if [ -f "$DB_PROPS" ]; then
    echo "  [OK]   db.properties exists locally"
    PASS=$((PASS + 1))
else
    echo "  [WARN] db.properties not found locally (may already be on remote)"
fi

echo ""
echo "[*] Testing remote DB connectivity via status.jsp..."
STATUS_BODY=$(curl -s --max-time 15 "$BASE_HTTPS/status.jsp" 2>/dev/null)
if echo "$STATUS_BODY" | grep -qi "Online"; then
    echo "  [OK]   status.jsp reports DB Online"
    PASS=$((PASS + 1))
elif echo "$STATUS_BODY" | grep -qi "Error\|Offline"; then
    echo "  [FAIL] status.jsp reports DB Offline/Error"
    FAIL=$((FAIL + 1))
else
    echo "  [WARN] Could not determine DB status from status.jsp"
fi

echo ""
echo "[*] Testing JSP DB rendering (species.jsp should not contain 'undefined')..."
SPECIES_BODY=$(curl -s --max-time 15 "$BASE_HTTPS/species.jsp?kingdom=Animalia" 2>/dev/null)
if echo "$SPECIES_BODY" | grep -qi "undefined"; then
    echo "  [FAIL] species.jsp contains 'undefined' — DB query may have failed"
    FAIL=$((FAIL + 1))
elif echo "$SPECIES_BODY" | grep -qi "Database error"; then
    echo "  [FAIL] species.jsp shows database error"
    FAIL=$((FAIL + 1))
else
    echo "  [OK]   species.jsp rendered clean (no 'undefined', no DB error)"
    PASS=$((PASS + 1))
fi

echo ""
echo "[*] Servlet endpoints..."
check "$BASE_HTTPS/api/status" "StatusApiServlet (/api/status)"
check "$BASE_HTTPS/api/species?level=class&kingdom=Animalia" "SpeciesApiServlet (class query)"

echo ""
echo "[*] Security check (WEB-INF blocked)..."
WEB_INF_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$BASE_HTTPS/WEB-INF/web.xml" 2>/dev/null)
if [ "$WEB_INF_STATUS" -ge 400 ] 2>/dev/null; then
    echo "  [OK]   ${WEB_INF_STATUS}  WEB-INF/web.xml (correctly blocked)"
    PASS=$((PASS + 1))
elif [ "$WEB_INF_STATUS" = "000" ]; then
    echo "  [NOCONN]   WEB-INF/web.xml"
    FAIL=$((FAIL + 1))
else
    echo "  [FAIL] ${WEB_INF_STATUS}  WEB-INF/web.xml (should be 403/404!)"
    FAIL=$((FAIL + 1))
fi

echo ""
echo "───────────────────────────────────────────────────────────────"
echo " Results: ${PASS} OK | ${REDIRECT} redirects | ${FAIL} failed"
echo "───────────────────────────────────────────────────────────────"

# Response headers
echo ""
echo "[*] Response headers (HTTPS root):"
curl -sI -L --max-time 10 "$BASE_HTTPS/" 2>/dev/null | head -20 | sed 's/^/  /'
