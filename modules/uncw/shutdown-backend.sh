#!/bin/bash
set -uo pipefail
MOD_ROOT="$(cd "$(dirname "$0")" && pwd)"; PID_FILE="$MOD_ROOT/data/pids/backend.pid"
echo ""; echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║  UNCW™ Backend — Shutdown                                               ║"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"; echo ""
if [ ! -f "$PID_FILE" ]; then echo "  [--] Not running"; else
PID=$(cat "$PID_FILE"); if ! kill -0 "$PID" 2>/dev/null; then echo "  [--] PID $PID gone"; rm -f "$PID_FILE"; else
echo -n "  [*] Stopping (PID $PID)... "; kill "$PID" 2>/dev/null; sleep 2
if kill -0 "$PID" 2>/dev/null; then kill -9 "$PID" 2>/dev/null; fi; rm -f "$PID_FILE"; echo "✓"; fi; fi; echo ""
