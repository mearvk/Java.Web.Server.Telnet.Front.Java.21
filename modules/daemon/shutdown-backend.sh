#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# NitroWebExpress™ — daemon Backend Shutdown
# Stops the ModuleLoaderDaemon TCP server.
# Usage: bash shutdown-backend.sh
# ═══════════════════════════════════════════════════════════════════════════════
set -uo pipefail

MOD_ROOT="$(cd "$(dirname "$0")" && pwd)"
PID_DIR="$MOD_ROOT/data/pids"
PID_FILE="$PID_DIR/backend.pid"

echo ""
echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║  daemon — ModuleLoaderDaemon Backend Shutdown                             ║"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"
echo ""

if [ ! -f "$PID_FILE" ]; then
    echo "  [--] ModuleLoaderDaemon not running (no PID file)"
else
    PID=$(cat "$PID_FILE")
    if ! kill -0 "$PID" 2>/dev/null; then
        echo "  [--] ModuleLoaderDaemon not running (PID $PID not found)"
        rm -f "$PID_FILE"
    else
        echo -n "  [*] Stopping ModuleLoaderDaemon (PID $PID)... "
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
        echo "  [✓] ModuleLoaderDaemon stopped"
    fi
fi

echo ""
echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║  daemon Stopped                                                           ║"
echo "║  Restart: bash start-backend.sh                                           ║"
echo "║  Start all: bash ../../scripts/start-all.sh                               ║"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"
echo ""
