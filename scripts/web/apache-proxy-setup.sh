#!/bin/bash
# Add Apache reverse proxy rules for all NWE webapp contexts
# Usage: sudo bash scripts/web/apache-proxy-setup.sh
set -e

APACHE_CONF="/etc/apache2/sites-available/000-default-le-ssl.conf"
[ ! -f "$APACHE_CONF" ] && APACHE_CONF="/etc/apache2/sites-enabled/default-ssl.conf"
[ ! -f "$APACHE_CONF" ] && APACHE_CONF=$(find /etc/apache2/sites-enabled -name "*ssl*" -o -name "*le*" 2>/dev/null | head -1)
[ ! -f "$APACHE_CONF" ] && APACHE_CONF="/etc/apache2/sites-enabled/000-default.conf"

if [ ! -f "$APACHE_CONF" ]; then
    echo "[FAIL] Cannot find Apache SSL config. Checked:"
    echo "  /etc/apache2/sites-available/000-default-le-ssl.conf"
    echo "  /etc/apache2/sites-enabled/default-ssl.conf"
    echo "  /etc/apache2/sites-enabled/000-default.conf"
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
