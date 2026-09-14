#!/usr/bin/env bash
# AE6E66™ — Module Install Script
# Location-independent, idempotent module installation.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MOD_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
NWE_ROOT="$(cd "$MOD_ROOT/../.." && pwd)"
PORTS_LIB="$NWE_ROOT/scripts/nwe-ports.sh"
DB_SETUP="$MOD_ROOT/servlets/setup-db.sh"

[[ -d "$NWE_ROOT" && -d "$NWE_ROOT/scripts" ]] || {
    echo "[FAIL] Unable to resolve NWE repository root: $NWE_ROOT" >&2
    exit 1
}

if [[ -f "$PORTS_LIB" ]]; then
    # shellcheck source=/dev/null
    source "$PORTS_LIB"
fi

echo "═══════════════════════════════════════════════════════════════"
echo " AE6E66™ — Module Install"
echo " Repository: $NWE_ROOT"
echo "═══════════════════════════════════════════════════════════════"

echo "[1/2] Database setup..."
if [[ -f "$DB_SETUP" ]]; then
    bash "$DB_SETUP"
    echo "  [✓] Database setup completed"
else
    echo "  [--] No setup-db.sh found; database setup skipped"
fi

echo
echo "[2/2] Configuring firewall..."
if declare -F nwe_ensure_ufw >/dev/null 2>&1; then
    nwe_ensure_ufw
fi

if command -v ufw >/dev/null 2>&1; then
    if [[ "$(id -u)" -eq 0 ]]; then
        ufw allow 8080/tcp >/dev/null
    elif command -v sudo >/dev/null 2>&1; then
        sudo ufw allow 8080/tcp >/dev/null
    else
        echo "[FAIL] UFW is installed but root/sudo access is unavailable." >&2
        exit 1
    fi
    echo "  [✓] Port 8080 (Tomcat) configured"
else
    echo "  [--] UFW unavailable; firewall configuration skipped"
fi

echo
echo "═══════════════════════════════════════════════════════════════"
echo " AE6E66™ install complete."
echo " Frontend: http://localhost:8080/ae6e66/"
echo "═══════════════════════════════════════════════════════════════"
