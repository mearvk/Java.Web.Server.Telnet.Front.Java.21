#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# AE6E66 — Backend Shutdown Script
# Stops all TCP backend servers.
# Usage: bash shutdown-backend.sh
# ═══════════════════════════════════════════════════════════════
set -uo pipefail

MOD_ROOT="$(cd "$(dirname "$0")" && pwd)"
PID_DIR="$MOD_ROOT/data/pids"

echo "═══════════════════════════════════════════════════════════════"
echo " AE6E66 — Backend Shutdown"
echo "═══════════════════════════════════════════════════════════════"
echo ""

STOPPED=0
SKIPPED=0

PID_FILE="$PID_DIR/backend.pid"

if [ ! -f "$PID_FILE" ]; then
    echo "  [SKIP] Backend — no PID file"
    SKIPPED=$((SKIPPED + 1))
else
    PID=$(cat "$PID_FILE")

    if ! kill -0 "$PID" 2>/dev/null; then
        echo "  [SKIP] Backend — PID $PID not running"
        rm -f "$PID_FILE"
        SKIPPED=$((SKIPPED + 1))
    else
        echo -n "  [*] Stopping backend (PID $PID)..."
        kill "$PID" 2>/dev/null
        sleep 2

        if kill -0 "$PID" 2>/dev/null; then
            kill -9 "$PID" 2>/dev/null
            sleep 1
        fi

        rm -f "$PID_FILE"
        echo " OK"
        STOPPED=$((STOPPED + 1))
    fi
fi

echo ""
echo "[✓] Stopped: $STOPPED | Skipped: $SKIPPED"
echo ""
echo "    Restart: bash start-backend.sh"
echo "═══════════════════════════════════════════════════════════════"
