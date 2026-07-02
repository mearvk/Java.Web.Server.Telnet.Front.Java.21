#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# Brarner.M.Alete™ — Backend Shutdown Script
# Stops all TCP backend servers (Postal, SSA, Art, Legal).
# Usage: bash shutdown-backend.sh
# ═══════════════════════════════════════════════════════════════
set -uo pipefail

BMA_ROOT="$(cd "$(dirname "$0")" && pwd)"
PID_DIR="$BMA_ROOT/data/pids"

echo "═══════════════════════════════════════════════════════════════"
echo " Brarner.M.Alete™ — Backend Shutdown"
echo "═══════════════════════════════════════════════════════════════"
echo ""

STOPPED=0
SKIPPED=0

for MODULE in postal ssa art legal; do
    PID_FILE="$PID_DIR/$MODULE.pid"

    if [ ! -f "$PID_FILE" ]; then
        echo "  [SKIP] $MODULE — no PID file"
        SKIPPED=$((SKIPPED + 1))
        continue
    fi

    PID=$(cat "$PID_FILE")

    if ! kill -0 "$PID" 2>/dev/null; then
        echo "  [SKIP] $MODULE — PID $PID not running"
        rm -f "$PID_FILE"
        SKIPPED=$((SKIPPED + 1))
        continue
    fi

    echo -n "  [*] Stopping $MODULE (PID $PID)..."
    kill "$PID" 2>/dev/null
    sleep 2

    if kill -0 "$PID" 2>/dev/null; then
        kill -9 "$PID" 2>/dev/null
        sleep 1
    fi

    rm -f "$PID_FILE"
    echo " OK"
    STOPPED=$((STOPPED + 1))
done

echo ""
echo "[✓] Stopped: $STOPPED | Skipped: $SKIPPED"
echo ""
echo "    Restart: bash start-backend.sh"
echo "═══════════════════════════════════════════════════════════════"
