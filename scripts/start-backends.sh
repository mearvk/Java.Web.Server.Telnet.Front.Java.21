#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# NitroWebExpress™ — Start All Backend Modules
# Starts individual backend TCP servers for all modules.
# Usage: bash scripts/start-backends.sh
#        bash scripts/start-backends.sh --stop (to stop all)
# ═══════════════════════════════════════════════════════════════════════════════
set -uo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

source "$PROJECT_ROOT/scripts/print-descriptor.sh" 2>/dev/null || true

# Module definitions: MOD_DIR -> Context
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

# Webapp-only modules (no backend)
WEBAPP_ONLY_MODULES=(
    "black-belt"
    "languages"
)

# ── Parse arguments ───────────────────────────────────────────────────────────
STOP_MODE=false
for arg in "$@"; do
    if [ "$arg" = "--stop" ]; then
        STOP_MODE=true
    fi
done

# ── STOP MODE ─────────────────────────────────────────────────────────────────
if [ "$STOP_MODE" = true ]; then
    echo "╔═══════════════════════════════════════════════════════════════════════════╗"
    echo "║  NitroWebExpress™ — Stop All Backend Modules                             ║"
    echo "╚═══════════════════════════════════════════════════════════════════════════╝"
    echo ""

    for MOD_DIR in "${!MODULES[@]}"; do
        MOD_PATH="$PROJECT_ROOT/modules/$MOD_DIR"

        if [ ! -f "$MOD_PATH/shutdown-backend.sh" ]; then
            continue
        fi

        echo -n "  [*] Stopping $MOD_DIR... "

        if cd "$MOD_PATH" && bash shutdown-backend.sh > /dev/null 2>&1; then
            echo "✓"
        else
            echo "✗"
        fi
    done

    # Stop Futures backend (if exists)
    FUTURES_PATH="$PROJECT_ROOT/modules/red/Futures"
    if [ -f "$FUTURES_PATH/shutdown-backend.sh" ]; then
        echo -n "  [*] Stopping Futures backend... "
        if cd "$FUTURES_PATH" && bash shutdown-backend.sh > /dev/null 2>&1; then
            echo "✓"
        else
            echo "✗"
        fi
    fi

    echo ""
    echo "╔═══════════════════════════════════════════════════════════════════════════╗"
    echo "║  All backend modules stopped.                                             ║"
    echo "╚═══════════════════════════════════════════════════════════════════════════╝"
    exit 0
fi

# ── START MODE ────────────────────────────────────────────────────────────────
echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║  NitroWebExpress™ — Start All Backend Modules                           ║"
echo "║  Backend Modules: ${#MODULES[@]}                                                     ║"
echo "║  Webapp-Only:     ${#WEBAPP_ONLY_MODULES[@]}                                                     ║"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"
echo ""

# ── Start Main.java (core servers: NWE, Strernary, Communicator, Signals, etc.)
echo "  [*] Starting NWE Main process (Strernary, Communicator, Signals, Crypto)..."
if [ -f "$PROJECT_ROOT/scripts/start-backend-modules.sh" ]; then
    bash "$PROJECT_ROOT/scripts/start-backend-modules.sh" 2>&1 | sed 's/^/      /'
    if [ -f "$PROJECT_ROOT/data/nwe-main.pid" ] && kill -0 "$(cat "$PROJECT_ROOT/data/nwe-main.pid" 2>/dev/null)" 2>/dev/null; then
        echo "  [✓] NWE Main started (PID $(cat "$PROJECT_ROOT/data/nwe-main.pid"))"
    else
        echo "  [!] NWE Main may have failed — check logging/nwe-main.log"
    fi
else
    echo "  [!] start-backend-modules.sh not found — core servers will not start"
fi
echo ""

# ── Start individual module backends ──────────────────────────────────────────
echo "  [*] Starting individual module backends..."
echo ""

SUCCESS=()
FAILED=()
SKIPPED=()

for MOD_DIR in "${!MODULES[@]}"; do
    MOD_PATH="$PROJECT_ROOT/modules/$MOD_DIR"

    if [ ! -d "$MOD_PATH" ]; then
        SKIPPED+=("$MOD_DIR: not found")
        continue
    fi

    if [ ! -f "$MOD_PATH/start-backend.sh" ]; then
        SKIPPED+=("$MOD_DIR: no start-backend.sh")
        continue
    fi

    echo -n "  [*] Starting $MOD_DIR backend... "

    set +e
    BACKEND_OUT=$(cd "$MOD_PATH" && bash start-backend.sh 2>&1)
    BACKEND_RC=$?
    set -e

    if [ $BACKEND_RC -eq 0 ]; then
        echo "✓"
        SUCCESS+=("$MOD_DIR")
    else
        echo "✗"
        # Show last line of error for quick diagnosis
        echo "$BACKEND_OUT" | grep -i "error\|fail\|exception\|not found" | tail -2 | sed 's/^/        /'
        FAILED+=("$MOD_DIR")
    fi
done

# Start Futures backend (if exists)
FUTURES_PATH="$PROJECT_ROOT/modules/red/Futures"
if [ -f "$FUTURES_PATH/start-backend.sh" ]; then
    echo -n "  [*] Starting Futures backend... "
    if cd "$FUTURES_PATH" && bash start-backend.sh > /dev/null 2>&1; then
        echo "✓"
        SUCCESS+=("Futures")
    else
        echo "✗"
        FAILED+=("Futures")
    fi
fi

echo ""

# Print summary
if [ ${#SUCCESS[@]} -gt 0 ]; then
    echo "  ✓ Started: ${#SUCCESS[@]} backends"
fi

if [ ${#SKIPPED[@]} -gt 0 ]; then
    echo "  - Skipped: ${#SKIPPED[@]} (no backend defined)"
fi

if [ ${#FAILED[@]} -gt 0 ]; then
    echo "  ✗ Failed: ${#FAILED[@]}"
    echo ""
    for MOD in "${FAILED[@]}"; do
        echo "    - $MOD"
    done
fi

echo ""
echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║  Backend Status Summary                                                 ║"
echo "║  Running: ${#SUCCESS[@]} / $(( ${#MODULES[@]} + 1 ))                                                    ║"
if [ ${#FAILED[@]} -gt 0 ]; then
    echo "║  Failed:  ${#FAILED[@]}                                                       ║"
fi
echo "║  Stop:    bash scripts/start-backends.sh --stop                         ║"
echo "║  Monitor: ps aux | grep java                                            ║"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"

[ ${#FAILED[@]} -eq 0 ]

