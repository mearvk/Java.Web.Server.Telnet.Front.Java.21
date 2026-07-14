#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# NitroWebExpress™ — Shutdown All Services
# Orchestrates complete shutdown sequence (reverse order):
#   1. Frontend modules (Tomcat webapps)
#   2. Backend modules (TCP servers)
#   3. MySQL
#
# Usage: bash scripts/shutdown-all.sh [tomcat_home] [--stop-tomcat]
# ═══════════════════════════════════════════════════════════════════════════════
set -uo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TOMCAT_HOME="${1:-${CATALINA_HOME:-/home/mearvk/tomcat}}"
STOP_TOMCAT="${2:-}"

echo ""
echo "╔══════════════════════════════════════════════════════════════════════════════"
echo "║                                                                              ║"
echo "║   ▌ NitroWebExpress™ — Complete System Shutdown                            ║"
echo "║   ▌ Sequence: Frontends → Backends → MySQL                                  ║"
echo "║   ▌                                                                          ║"
echo "╚══════════════════════════════════════════════════════════════════════════════╝"
echo ""

# ── Phase 1: Frontend Modules ─────────────────────────────────────────────────
echo ""
echo "───────────────────────────────────────────────────────────────────────────────"
echo "Phase 1/3: Shutting Down Frontend Modules..."
echo "───────────────────────────────────────────────────────────────────────────────"
echo ""

if bash "$PROJECT_ROOT/scripts/shutdown-frontends.sh" "$TOMCAT_HOME" $STOP_TOMCAT; then
    echo ""
    echo "  [✓] Frontend shutdown complete"
else
    echo ""
    echo "  [!] Some frontends failed to stop (continuing anyway)"
fi

sleep 2

# ── Phase 2: Backend Modules ──────────────────────────────────────────────────
echo ""
echo "───────────────────────────────────────────────────────────────────────────────"
echo "Phase 2/3: Shutting Down Backend Modules..."
echo "───────────────────────────────────────────────────────────────────────────────"
echo ""

if bash "$PROJECT_ROOT/scripts/shutdown-backends.sh"; then
    echo ""
    echo "  [✓] Backend shutdown complete"
else
    echo ""
    echo "  [!] Some backends failed to stop (continuing anyway)"
fi

sleep 2

# ── Phase 3: MySQL ───────────────────────────────────────────────────────────
echo ""
echo "───────────────────────────────────────────────────────────────────────────────"
echo "Phase 3/3: Shutting Down MySQL..."
echo "───────────────────────────────────────────────────────────────────────────────"
echo ""

if bash "$PROJECT_ROOT/scripts/shutdown-mysql.sh"; then
    echo ""
    echo "  [✓] MySQL shutdown complete"
else
    echo ""
    echo "  [!] MySQL shutdown had issues"
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo ""
echo "╔══════════════════════════════════════════════════════════════════════════════"
echo "║                                                                              ║"
echo "║   ✓ NitroWebExpress™ System Shutdown Complete!                             ║"
echo "║                                                                              ║"
echo "║   NEXT STEPS:                                                                ║"
echo "║   • Verify services stopped: bash scripts/status.sh                         ║"
echo "║   • Restart system: bash scripts/start-all.sh                               ║"
echo "║   • View logs: tail -f logging/*.log                                        ║"
echo "║                                                                              ║"
echo "╚══════════════════════════════════════════════════════════════════════════════╝"
echo ""

