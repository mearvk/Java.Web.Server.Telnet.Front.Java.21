#!/bin/bash
# Add Apache reverse proxy rules for all NWE webapp contexts
# Usage: sudo bash scripts/web/apache-proxy-setup.sh
set -e

APACHE_CONF=""
for F in \
    /etc/apache2/sites-available/000-default-le-ssl.conf \
    /etc/apache2/sites-enabled/default-ssl.conf \
    /etc/apache2/sites-available/default-ssl.conf \
    /etc/apache2/sites-enabled/000-default.conf \
    /etc/apache2/sites-available/000-default.conf \
    /etc/httpd/conf.d/ssl.conf \
    /etc/httpd/conf/httpd.conf; do
    [ -f "$F" ] && APACHE_CONF="$F" && break
done

# If still not found, search for any config with VirtualHost *:443
if [ -z "$APACHE_CONF" ]; then
    APACHE_CONF=$(grep -rl "VirtualHost.*443" /etc/apache2/ /etc/httpd/ 2>/dev/null | head -1)
fi

# Last resort: any enabled site
if [ -z "$APACHE_CONF" ]; then
    APACHE_CONF=$(find /etc/apache2/sites-enabled /etc/apache2/sites-available /etc/httpd/conf.d -name "*.conf" 2>/dev/null | head -1)
fi

if [ -z "$APACHE_CONF" ] || [ ! -f "$APACHE_CONF" ]; then
    echo "[FAIL] Cannot find any Apache config."
    echo "  Searched: /etc/apache2/, /etc/httpd/"
    echo ""
    echo "  Listing available configs:"
    ls /etc/apache2/sites-enabled/ /etc/apache2/sites-available/ /etc/httpd/conf.d/ 2>/dev/null || true
    echo ""
    echo "  Run manually: sudo find /etc -name '*.conf' | xargs grep -l VirtualHost"
    exit 1
fi

echo "[*] Apache config: $APACHE_CONF"

# All webapp contexts that need proxying
CONTEXTS=(
    "brarner.m.alete"
    "ae6e66"
    "futures"
    "gdgh"
    "gray-registry"
    "gray85-registry"
    "blackbelt"
    "languages"
    "strernary"
    "california-fbi"
    "california-cia"
    "california-nsa"
    "duke"
    "stanford-library"
)

# Check which are already configured
ADDED=0
for CTX in "${CONTEXTS[@]}"; do
    if grep -q "/$CTX/" "$APACHE_CONF" 2>/dev/null; then
        echo "  [SKIP] /$CTX/ — already in config"
    else
        # Insert ProxyPass before </VirtualHost>
        sed -i "/<\/VirtualHost>/i\\    ProxyPass /$CTX/ http://localhost:8080/$CTX/\\n    ProxyPassReverse /$CTX/ http://localhost:8080/$CTX/" "$APACHE_CONF"
        echo "  [ADDED] /$CTX/ → http://localhost:8080/$CTX/"
        ADDED=$((ADDED + 1))
    fi
done

# Ensure proxy modules are enabled
a2enmod proxy proxy_http 2>/dev/null || true

if [ $ADDED -gt 0 ]; then
    echo ""
    echo "[*] Reloading Apache..."
    systemctl reload apache2 2>/dev/null || apachectl graceful 2>/dev/null
    echo "[OK] $ADDED ProxyPass rules added. Apache reloaded."
else
    echo "[OK] All contexts already configured."
fi
