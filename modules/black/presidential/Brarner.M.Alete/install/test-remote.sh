#!/usr/bin/env bash
# Brarner.M.Alete™ — Remote Connectivity Test
# Tests the BMA servlet website on the remote server via HTTPS
# Usage: bash install/test-remote.sh [domain]

DOMAIN="${1:-lauradei.us}"
BASE_HTTP="http://${DOMAIN}/brarner.m.alete"
BASE_HTTPS="https://${DOMAIN}/brarner.m.alete"

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
    local status headers
    status=$(curl -s -o /dev/null -w "%{http_code}" -L --max-time 10 "$url" 2>/dev/null)
    if [ "$status" -ge 200 ] && [ "$status" -lt 300 ] 2>/dev/null; then
        echo "  [OK]       ${status}  ${label}"
        PASS=$((PASS + 1))
    elif [ "$status" -ge 300 ] && [ "$status" -lt 400 ] 2>/dev/null; then
        local location
        location=$(curl -s -o /dev/null -w "%{redirect_url}" --max-time 5 "$url" 2>/dev/null)
        echo "  [REDIRECT] ${status}  ${label} → ${location}"
        REDIRECT=$((REDIRECT + 1))
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
check "$BASE_HTTP/" "HTTP root (should redirect)"

echo ""
echo "[*] HTTPS pages..."
check "$BASE_HTTPS/" "Root/Index"
check "$BASE_HTTPS/index.html" "index.html"
check "$BASE_HTTPS/index.jsp" "index.jsp"

# BMA tabs
check "$BASE_HTTPS/overview" "Overview tab"
check "$BASE_HTTPS/species" "Species tab"
check "$BASE_HTTPS/postal" "Postal tab"
check "$BASE_HTTPS/art" "Art tab"
check "$BASE_HTTPS/science" "Science tab"
check "$BASE_HTTPS/status" "Status tab"

# Static resources
check "$BASE_HTTPS/images/logo/mearvk.ltd.logo.png" "Logo image"

# Servlet endpoints
check "$BASE_HTTPS/servlet/status" "Servlet: status"
check "$BASE_HTTPS/servlet/species" "Servlet: species"
check "$BASE_HTTPS/servlet/postal" "Servlet: postal"

echo ""
echo "───────────────────────────────────────────────────────────────"
echo " Results: ${PASS} OK | ${REDIRECT} redirects | ${FAIL} failed"
echo "───────────────────────────────────────────────────────────────"

# Response headers for diagnosis
echo ""
echo "[*] Response headers (HTTPS root):"
curl -sI -L --max-time 10 "$BASE_HTTPS/" 2>/dev/null | head -20 | sed 's/^/  /'
