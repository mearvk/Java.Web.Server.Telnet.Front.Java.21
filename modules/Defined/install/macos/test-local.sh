#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# Defined™ — Test Local Deployment (macOS)
# In memory of Steve Jobs. Think Different.
# NitroWebExpress™ — MEARVK LLC
# ═══════════════════════════════════════════════════════════════════════════════

echo ""
echo "╔═══════════════════════════════════════════════════════════════════════╗"
echo "║  Defined™ — Test Local (macOS)                                        ║"
echo "║  In memory of Steve Jobs.                                             ║"
echo "╚═══════════════════════════════════════════════════════════════════════╝"
echo ""

echo "  [*] Testing Tomcat webapp at /defined/..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/defined/ 2>/dev/null || echo "000")
echo "      HTTP $HTTP_CODE"

echo "  [*] Testing AI server on port 49220..."
if timeout 2 bash -c "echo >/dev/tcp/localhost/49220" 2>/dev/null; then
    echo "      [OK] Port 49220 is UP"
else
    echo "      [--] Port 49220 is DOWN"
fi

echo "  [*] Testing protocol backend on port 49221..."
if timeout 2 bash -c "echo >/dev/tcp/localhost/49221" 2>/dev/null; then
    echo "      [OK] Port 49221 is UP"
else
    echo "      [--] Port 49221 is DOWN"
fi

echo ""
