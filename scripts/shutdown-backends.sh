#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# NitroWebExpress™ — Shutdown All Backend Modules
# Stops all backend TCP servers for all modules.
# Usage: bash scripts/shutdown-backends.sh
# ═══════════════════════════════════════════════════════════════════════════════
set -uo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$PROJECT_ROOT/scripts/print-descriptor.sh" 2>/dev/null || true

# Module definitions
declare -A MODULES=(
    ["AE6E66"]="ae6e66"
    ["cia"]="california-cia"
    ["duke"]="california-duke"
    ["fbi"]="california-fbi"
    ["gray"]="gray-registry"
    ["gray.a85"]="gray85-registry"
    ["Green.Durham.Grass.and.Herb"]="gdgh"
    ["library"]="library"
    ["nsa"]="california-nsa"
)

echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║  NitroWebExpress™ — Shutdown All Backend Modules                         ║"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"
echo ""

SUCCESS=()
FAILED=()

for MOD_DIR in "${!MODULES[@]}"; do
    MOD_PATH="$PROJECT_ROOT/modules/$MOD_DIR"

    if [ ! -d "$MOD_PATH" ]; then
        continue
    fi

    if [ ! -f "$MOD_PATH/shutdown-backend.sh" ]; then
        continue
    fi

    echo -n "  [*] Stopping $MOD_DIR backend... "

    if cd "$MOD_PATH" && bash shutdown-backend.sh > /dev/null 2>&1; then
        echo "✓"
        SUCCESS+=("$MOD_DIR")
    else
        echo "✗"
        FAILED+=("$MOD_DIR")
    fi
done

# Stop Futures backend (if exists)
FUTURES_PATH="$PROJECT_ROOT/modules/red/Futures"
if [ -f "$FUTURES_PATH/shutdown-backend.sh" ]; then
    echo -n "  [*] Stopping Futures backend... "
    if cd "$FUTURES_PATH" && bash shutdown-backend.sh > /dev/null 2>&1; then
        echo "✓"
        SUCCESS+=("Futures")
    else
        echo "✗"
        FAILED+=("Futures")
    fi
fi

echo ""
echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║  Backend Shutdown Summary                                                 ║"
echo "║  Stopped: ${#SUCCESS[@]}                                                  ║"
if [ ${#FAILED[@]} -gt 0 ]; then
    echo "║  Failed:  ${#FAILED[@]}                                                 ║"
fi
echo "╚═══════════════════════════════════════════════════════════════════════════╝"

[ ${#FAILED[@]} -eq 0 ]

