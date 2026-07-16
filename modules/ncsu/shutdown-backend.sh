#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════════
# NitroWebExpress™ — ncsu Backend Shutdown
# Stops the TCP backend server.
# Usage: bash shutdown-backend.sh
# ═══════════════════════════════════════════════════════════════════════════════════
set -uo pipefail

MOD_ROOT="$(cd "$(dirname "$0")" && pwd)"
PID_DIR="$MOD_ROOT/data/pids"

echo ""
echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║  ncsu Backend Server — Shutdown                                         ║"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"
echo ""

PID_FILE="$PID_DIR/backend.pid"

if [ ! -f "$PID_FILE" ]; then
    echo "  [--] Backend not running (no PID file)"
else
    PID=$(cat "$PID_FILE")

    if ! kill -0 "$PID" 2>/dev/null; then
        echo "  [--] Backend not running (PID $PID not found)"
        rm -f "$PID_FILE"
    else
        echo -n "  [*] Stopping backend (PID $PID)... "
        kill "$PID" 2>/dev/null
        sleep 2

        if kill -0 "$PID" 2>/dev/null; then
            echo "(force)"
            kill -9 "$PID" 2>/dev/null
            sleep 1
        else
            echo "✓"
        fi

        rm -f "$PID_FILE"
        echo "  [✓] Backend stopped"
    fi
fi

echo ""
echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║  ncsu Backend Stopped                                                   ║"
echo "║                                                                            ║"
echo "║  Management:                                                               ║"
echo "║  Restart backend:  bash start-backend.sh                                  ║"
echo "║  Start all:        bash ../../scripts/start-all.sh                        ║"
echo "║  Shutdown all:     bash ../../scripts/shutdown-all.sh                     ║"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"
echo ""
