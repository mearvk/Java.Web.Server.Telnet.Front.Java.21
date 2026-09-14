#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# NitroWebExpress™ — Shutdown Backend Modules (macOS)
# Stops the NWE Main process and all backend TCP servers.
# Usage: bash scripts/shutdown-backends-macos.sh
# ═══════════════════════════════════════════════════════════════════════════════

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PID_FILE="$PROJECT_ROOT/data/nwe-main.pid"

echo "[*] Shutting down NWE backend modules..."

# ── Kill from main PID file ───────────────────────────────────────────────────
if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    if kill -0 "$PID" 2>/dev/null; then
        kill "$PID" 2>/dev/null
        sleep 2
        # Force kill if still running
        kill -0 "$PID" 2>/dev/null && kill -9 "$PID" 2>/dev/null
        echo "[OK] Main process (PID $PID) terminated"
    else
        echo "[--] Process $PID was not running"
    fi
    rm -f "$PID_FILE"
else
    echo "[--] No PID file found"
fi

# ── Kill module backend PIDs ──────────────────────────────────────────────────
for MOD in AE6E66 cia duke fbi gray gray.a85 Green.Durham.Grass.and.Herb library nsa; do
    MOD_PID="$PROJECT_ROOT/modules/$MOD/data/pids/backend.pid"
    if [ -f "$MOD_PID" ]; then
        MPID=$(cat "$MOD_PID")
        kill "$MPID" 2>/dev/null
        rm -f "$MOD_PID"
        echo "  [OK] $MOD stopped"
    fi
done

# Futures
FUTURES_PID="$PROJECT_ROOT/modules/red/Futures/data/pids/backend.pid"
if [ -f "$FUTURES_PID" ]; then
    FPID=$(cat "$FUTURES_PID")
    kill "$FPID" 2>/dev/null
    rm -f "$FUTURES_PID"
    echo "  [OK] Futures stopped"
fi

echo ""
echo "[OK] All backend modules stopped"
