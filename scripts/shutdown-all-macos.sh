#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# NitroWebExpress™ — Shutdown All Services (macOS)
# Sequence: Frontends → Backends → MySQL
# Usage: bash scripts/shutdown-all-macos.sh
# ═══════════════════════════════════════════════════════════════════════════════
set -uo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo ""
echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║                                                                           ║"
echo "║   NitroWebExpress™ — Complete System Shutdown (macOS)                     ║"
echo "║   Sequence: Frontends → Backends → MySQL                                  ║"
echo "║                                                                           ║"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"
echo ""

# ── Phase 1: Frontends / Tomcat ───────────────────────────────────────────────
echo "───────────────────────────────────────────────────────────────────────────────"
echo "Phase 1/3: Shutting Down Frontend Modules / Tomcat..."
echo "───────────────────────────────────────────────────────────────────────────────"
echo ""

brew services stop tomcat 2>/dev/null && echo "  [OK] Tomcat stopped via brew" || {
    TOMCAT_HOME="${CATALINA_HOME:-/opt/homebrew/opt/tomcat/libexec}"
    [ -x "$TOMCAT_HOME/bin/shutdown.sh" ] && "$TOMCAT_HOME/bin/shutdown.sh" 2>/dev/null && echo "  [OK] Tomcat stopped"
}
sleep 2

# ── Phase 2: Backends ─────────────────────────────────────────────────────────
echo ""
echo "───────────────────────────────────────────────────────────────────────────────"
echo "Phase 2/3: Shutting Down Backend Modules..."
echo "───────────────────────────────────────────────────────────────────────────────"
echo ""

if [ -f "$PROJECT_ROOT/scripts/shutdown-backends.sh" ]; then
    bash "$PROJECT_ROOT/scripts/shutdown-backends.sh"
    echo "  [OK] Backend shutdown complete"
else
    # Manual PID kill
    PID_FILE="$PROJECT_ROOT/data/nwe-main.pid"
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        kill "$PID" 2>/dev/null && echo "  [OK] Main process (PID $PID) terminated" || echo "  [--] Process $PID not running"
        rm -f "$PID_FILE"
    else
        echo "  [--] No PID file — backends may not be running"
    fi
fi
sleep 2

# ── Phase 3: MySQL ────────────────────────────────────────────────────────────
echo ""
echo "───────────────────────────────────────────────────────────────────────────────"
echo "Phase 3/3: Shutting Down MySQL..."
echo "───────────────────────────────────────────────────────────────────────────────"
echo ""

brew services stop mysql 2>/dev/null && echo "  [OK] MySQL stopped via brew" || echo "  [--] MySQL not running"

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║                                                                           ║"
echo "║   ✓ NitroWebExpress™ System Shutdown Complete! (macOS)                    ║"
echo "║   Restart: bash scripts/start-all-macos.sh                                ║"
echo "║                                                                           ║"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"
echo ""
