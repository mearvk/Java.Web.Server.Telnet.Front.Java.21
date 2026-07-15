#!/bin/bash
# NitroWebExpress™ — Patch all WEB-INF/web.xml for security best practices + check SSL
# Adds session-config, security headers, security-constraint to any web.xml missing them.
# Also validates SSL certs for deployed Tomcat.
# Usage: bash scripts/web/patch-webinf-and-ssl.sh
set -uo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PASS=0; FAIL=0

echo "═══════════════════════════════════════════════════════════════"
echo " NitroWebExpress™ — WEB-INF Patch & SSL Verification"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# ── 1. Patch web.xml files ────────────────────────────────────────────────────
echo "[1/2] Patching WEB-INF/web.xml files..."

# Find all source web.xml (skip target/ and work/ dirs)
WEB_XMLS=$(find "$PROJECT_ROOT" -path "*/src/main/webapp/WEB-INF/web.xml" | sort)

for WX in $WEB_XMLS; do
    MODULE=$(echo "$WX" | sed "s|$PROJECT_ROOT/||" | cut -d/ -f1-3)

    # Check if session-timeout already present
    if grep -q "session-timeout" "$WX" 2>/dev/null; then
        echo "  [OK] $MODULE — already patched"
        PASS=$((PASS + 1))
        continue
    fi

    # Inject security block before </web-app>
    if grep -q "</web-app>" "$WX"; then
        # Use python for reliable multiline insertion
        python3 -c "
import sys
block = '''    <!-- NWE Security (auto-patched) -->
    <session-config>
        <session-timeout>30</session-timeout>
        <cookie-config><http-only>true</http-only></cookie-config>
    </session-config>
    <security-constraint>
        <web-resource-collection>
            <web-resource-name>Protected</web-resource-name>
            <url-pattern>/WEB-INF/*</url-pattern>
        </web-resource-collection>
        <auth-constraint/>
    </security-constraint>
    <error-page><error-code>404</error-code><location>/index.jsp</location></error-page>
    <error-page><error-code>500</error-code><location>/index.jsp</location></error-page>
'''
content = open(sys.argv[1]).read()
content = content.replace('</web-app>', block + '</web-app>')
open(sys.argv[1], 'w').write(content)
" "$WX"
        echo "  [PATCHED] $MODULE — session/security/error-pages added"
        PASS=$((PASS + 1))
    else
        echo "  [FAIL] $MODULE — no </web-app> closing tag found"
        FAIL=$((FAIL + 1))
    fi
done

# ── 2. SSL Certificate Verification ──────────────────────────────────────────
echo ""
echo "[2/2] SSL Certificate Verification..."

# Check Tomcat SSL (port 8443 or configured HTTPS)
TOMCAT_HOME="${CATALINA_HOME:-/opt/apache-tomcat-11.0.2}"
TOMCAT_SSL_CONF="$TOMCAT_HOME/conf/server.xml"
DOMAINS=("lauradei.us" "localhost")

# Check Let's Encrypt cert
CERT_DIR="/etc/letsencrypt/live"
if [ -d "$CERT_DIR" ]; then
    for DOMAIN_DIR in "$CERT_DIR"/*/; do
        DOMAIN=$(basename "$DOMAIN_DIR")
        CERT="$DOMAIN_DIR/fullchain.pem"
        if [ -f "$CERT" ]; then
            EXPIRY=$(openssl x509 -enddate -noout -in "$CERT" 2>/dev/null | cut -d= -f2)
            EXPIRY_EPOCH=$(date -d "$EXPIRY" +%s 2>/dev/null || echo 0)
            NOW_EPOCH=$(date +%s)
            DAYS_LEFT=$(( (EXPIRY_EPOCH - NOW_EPOCH) / 86400 ))
            if [ $DAYS_LEFT -gt 30 ]; then
                echo "  [OK] $DOMAIN — SSL valid ($DAYS_LEFT days remaining)"
                PASS=$((PASS + 1))
            elif [ $DAYS_LEFT -gt 0 ]; then
                echo "  [WARN] $DOMAIN — SSL expiring soon ($DAYS_LEFT days)"
                PASS=$((PASS + 1))
            else
                echo "  [FAIL] $DOMAIN — SSL EXPIRED"
                FAIL=$((FAIL + 1))
            fi
        fi
    done
else
    echo "  [INFO] No Let's Encrypt certs at $CERT_DIR"
fi

# Check Tomcat PKCS12 keystore
KEYSTORE="$PROJECT_ROOT/psychiatry/secrets/server.p12"
if [ -f "$KEYSTORE" ]; then
    PASS_ENV="${NWE_KEYSTORE_PASS:-changeit}"
    EXPIRY=$(keytool -list -v -keystore "$KEYSTORE" -storepass "$PASS_ENV" -storetype PKCS12 2>/dev/null | grep "until:" | head -1 | sed 's/.*until: //')
    if [ -n "$EXPIRY" ]; then
        echo "  [OK] server.p12 keystore found — expires: $EXPIRY"
        PASS=$((PASS + 1))
    else
        echo "  [WARN] server.p12 exists but cannot read expiry (check password)"
    fi
else
    echo "  [INFO] No server.p12 keystore — TLS disabled for TCP services (HTTP via Apache/Tomcat)"
fi

# Check Apache SSL
if [ -f /etc/apache2/sites-enabled/default-ssl.conf ] || [ -f /etc/apache2/sites-enabled/*ssl*.conf ] 2>/dev/null; then
    echo "  [OK] Apache SSL site config found"
    PASS=$((PASS + 1))
elif [ -f /etc/httpd/conf.d/ssl.conf ]; then
    echo "  [OK] Apache (httpd) SSL config found"
    PASS=$((PASS + 1))
else
    echo "  [INFO] No Apache SSL config detected"
fi

# Live SSL test against known domain
for DOMAIN in "${DOMAINS[@]}"; do
    if echo | openssl s_client -connect "$DOMAIN:443" -servername "$DOMAIN" 2>/dev/null | openssl x509 -noout -dates 2>/dev/null | grep -q "notAfter"; then
        EXPIRY=$(echo | openssl s_client -connect "$DOMAIN:443" -servername "$DOMAIN" 2>/dev/null | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2)
        echo "  [OK] $DOMAIN:443 — live SSL responding (expires: $EXPIRY)"
        PASS=$((PASS + 1))
    fi
done

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo " Results: $PASS passed | $FAIL failed"
echo "═══════════════════════════════════════════════════════════════"
