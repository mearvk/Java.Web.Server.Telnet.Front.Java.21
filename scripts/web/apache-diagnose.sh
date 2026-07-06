#!/bin/bash
# Diagnose which Apache config is actually serving HTTPS for lauradei.us
# Usage: sudo bash scripts/web/apache-diagnose.sh
echo "=== Enabled sites ==="
ls -la /etc/apache2/sites-enabled/ 2>/dev/null

echo ""
echo "=== Which configs mention lauradei or 443 ==="
grep -rl "lauradei\|ServerName\|443" /etc/apache2/sites-enabled/ 2>/dev/null

echo ""
echo "=== Active VirtualHost *:443 blocks ==="
grep -n "VirtualHost\|ServerName\|ProxyPass\|SSLCert" /etc/apache2/sites-enabled/*.conf 2>/dev/null

echo ""
echo "=== Apache ports ==="
cat /etc/apache2/ports.conf 2>/dev/null | grep -v "^#"

echo ""
echo "=== Full test: which config handles lauradei.us:443 ==="
apache2ctl -S 2>/dev/null | grep -i "443\|lauradei\|default"
