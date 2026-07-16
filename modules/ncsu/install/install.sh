#!/bin/bash
# NC State University™ — Module Install Script
# Ensures UFW firewall is installed/enabled and module ports are open.
# Usage: sudo bash install/install.sh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MOD_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
NWE_ROOT="$(cd "$MOD_ROOT/../.." 2>/dev/null && pwd)"
[ -f "$NWE_ROOT/scripts/nwe-ports.sh" ] && source "$NWE_ROOT/scripts/nwe-ports.sh"

echo "═══════════════════════════════════════════════════════════════"
echo " NC State University™ — Module Install"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# 1. Database setup
echo "[1/2] Database setup..."
if [ -f "$MOD_ROOT/servlets/setup-db.sh" ]; then
    bash "$MOD_ROOT/servlets/setup-db.sh" && echo "  [✓] Database nwe_ncsu ready" || echo "  [!] Database setup had issues"
else
    echo "  [--] No setup-db.sh found (database may already exist)"
fi

# 2. Firewall (UFW install + enable + open ports)
echo ""
echo "[2/2] Configuring firewall..."
if type nwe_ensure_ufw &>/dev/null; then
    nwe_ensure_ufw
    sudo ufw allow 8080/tcp >/dev/null 2>&1 && echo "  [✓] Port 8080 (Tomcat) opened" || true
    sudo ufw allow 49217/tcp >/dev/null 2>&1 && echo "  [✓] Port 49217 (backend) opened" || true
else
    echo "  [--] NWE port library not available — installing UFW manually..."
    if command -v apt-get &>/dev/null; then
        sudo apt-get install -y -qq ufw >/dev/null 2>&1
    elif command -v dnf &>/dev/null; then
        sudo dnf install -y -q ufw >/dev/null 2>&1
    fi
    if command -v ufw &>/dev/null; then
        sudo ufw allow 22/tcp >/dev/null 2>&1
        sudo ufw allow 8080/tcp >/dev/null 2>&1
        sudo ufw allow 49217/tcp >/dev/null 2>&1
        sudo ufw --force enable >/dev/null 2>&1
        echo "  [✓] UFW installed and ports opened"
    else
        echo "  [!] Could not install UFW — open ports manually"
    fi
fi

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo " NC State University™ install complete."
echo " Backend port: 49217"
echo " Frontend:     http://localhost:8080/california-ncsu/"
echo "═══════════════════════════════════════════════════════════════"
