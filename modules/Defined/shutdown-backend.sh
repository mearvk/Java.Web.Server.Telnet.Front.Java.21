#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════════
# NitroWebExpress™ — Defined™ Backend Shutdown
# Theme: Dark Gray — Definition to Narrow Cause
# Usage: bash shutdown-backend.sh
# ═══════════════════════════════════════════════════════════════════════════════════
set -uo pipefail

MOD_ROOT="$(cd "$(dirname "$0")" && pwd)"
PID_FILE="$MOD_ROOT/data/pids/backend.pid"

echo ""
echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║  Defined™ Backend Server — Shutdown                                      ║"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"
echo ""

if [ ! -f "$PID_FILE" ]; then
    echo "  [--] No PID file found. Backend may not be running."
    exit 0
fi

PID=$(cat "$PID_FILE")

if kill -0 "$PID" 2>/dev/null; then
    kill "$PID"
    sleep 2
    if kill -0 "$PID" 2>/dev/null; then
        kill -9 "$PID"
    fi
    echo "  [✓] Backend stopped (PID $PID)"
else
    echo "  [--] Process $PID not running (stale PID file)"
fi

rm -f "$PID_FILE"
echo ""
