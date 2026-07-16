#!/bin/bash
# UNC Chapel Hill™ — Module Install Script
# Usage: sudo bash install/install.sh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MOD_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
NWE_ROOT="$(cd "$MOD_ROOT/../.." 2>/dev/null && pwd)"
[ -f "$NWE_ROOT/scripts/nwe-ports.sh" ] && source "$NWE_ROOT/scripts/nwe-ports.sh"

echo "═══════════════════════════════════════════════════════════════"
echo " UNC Chapel Hill™ — Module Install"
echo "═══════════════════════════════════════════════════════════════"
echo ""

echo "[1/2] Database setup..."
if [ -f "$MOD_ROOT/servlets/setup-db.sh" ]; then
    bash "$MOD_ROOT/servlets/setup-db.sh" && echo "  [✓] Database nwe_unc ready" || echo "  [!] Database setup had issues"
else
    echo "  [--] No setup-db.sh found"
fi

echo ""
echo "[2/2] Configuring firewall..."
if type nwe_ensure_ufw &>/dev/null; then
    nwe_ensure_ufw
    sudo ufw allow 8080/tcp >/dev/null 2>&1 && echo "  [✓] Port 8080 (Tomcat) opened" || true
    sudo ufw allow 49218/tcp >/dev/null 2>&1 && echo "  [✓] Port 49218 (backend) opened" || true
else
    if command -v ufw &>/dev/null; then
        sudo ufw allow 22/tcp >/dev/null 2>&1
        sudo ufw allow 8080/tcp >/dev/null 2>&1
        sudo ufw allow 49218/tcp >/dev/null 2>&1
        sudo ufw --force enable >/dev/null 2>&1
        echo "  [✓] UFW ports opened"
    else
        echo "  [--] UFW not available — open ports manually"
    fi
fi

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo " UNC Chapel Hill™ install complete."
echo " Backend port: 49218"
echo " Frontend:     http://localhost:8080/california-unc/"
echo "═══════════════════════════════════════════════════════════════"
