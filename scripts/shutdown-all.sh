#!/bin/bash
# ════════════════════════════════════════════════════════════════════════════════
# NitroWebExpress™ — Shutdown All Services
# Orchestrates complete shutdown sequence (reverse order):
#   1. Frontend modules (Tomcat webapps)
#   2. Backend modules (TCP servers)
#   3. MySQL
#
# Usage: bash scripts/shutdown-all.sh [tomcat_home] [--stop-tomcat]
# ════════════════════════════════════════════════════════════════════════════════
set -uo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

resolve_tomcat_home() {
    local requested="${1:-${CATALINA_HOME:-}}"
    if [ -n "$requested" ] && [ -d "$requested/webapps" ]; then
        printf '%s\n' "$requested"
        return 0
    fi

    if uname -s | grep -qi 'darwin'; then
        for candidate in \
            "/opt/homebrew/opt/tomcat/libexec" \
            "/usr/local/opt/tomcat/libexec" \
            "/Applications/Tomcat/apache-tomcat-11.0.2"; do
            if [ -d "$candidate/webapps" ]; then
                printf '%s\n' "$candidate"
                return 0
            fi
        done
    else
        for candidate in \
            "/opt/apache-tomcat-11.0.2" \
            "/opt/tomcat" \
            "/var/lib/tomcat9" \
            "/usr/share/tomcat"; do
            if [ -d "$candidate/webapps" ]; then
                printf '%s\n' "$candidate"
                return 0
            fi
        done
    fi

    printf '%s\n' "${requested:-${CATALINA_HOME:-/opt/apache-tomcat-11.0.2}}"
}

TOMCAT_HOME="$(resolve_tomcat_home "${1:-}")"
source "$PROJECT_ROOT/scripts/print-descriptor.sh" 2>/dev/null || true
STOP_TOMCAT="${2:-}"

echo ""
echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║   NitroWebExpress™ — Complete System Shutdown                         ║"
echo "║   Sequence: Frontends → Backends → MySQL                              ║"
echo "║   Tomcat: $TOMCAT_HOME                                                ║"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"
echo ""

# ── Phase 1: Frontend Modules ─────────────────────────────────────────────────
echo ""
echo "───────────────────────────────────────────────────────────────────────"
echo "Phase 1/3: Shutting Down Frontend Modules..."
echo "───────────────────────────────────────────────────────────────────────"
echo ""

if bash "$PROJECT_ROOT/scripts/shutdown-frontends.sh" "$TOMCAT_HOME" "$STOP_TOMCAT"; then
    echo ""
    echo "  [✓] Frontend shutdown complete"
else
    echo ""
    echo "  [!] Some frontends failed to stop (continuing anyway)"
fi

sleep 2

# ── Phase 2: Backend Modules ──────────────────────────────────────────────────
echo ""
echo "───────────────────────────────────────────────────────────────────────"
echo "Phase 2/3: Shutting Down Backend Modules..."
echo "───────────────────────────────────────────────────────────────────────"
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
echo "───────────────────────────────────────────────────────────────────────"
echo "Phase 3/3: Shutting Down MySQL..."
echo "───────────────────────────────────────────────────────────────────────"
echo ""

if bash "$PROJECT_ROOT/scripts/shutdown-mysql.sh"; then
    echo ""
    echo "  [✓] MySQL shutdown complete"
else
    echo ""
    echo "  [!] MySQL shutdown had issues"
fi

# ── Close Firewall Ports ──────────────────────────────────────────────────────
echo ""
echo "───────────────────────────────────────────────────────────────────────"
echo "Closing Firewall Ports..."
echo "───────────────────────────────────────────────────────────────────────"
echo ""

source "$PROJECT_ROOT/scripts/nwe-ports.sh"
if ! nwe_close_ports; then
    echo "  [!] Firewall cleanup skipped or failed (non-Linux or unsupported host)"
fi

# ── Summary ────────────────────────────────────────────────────────────────
echo ""
echo ""
echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║   ✓ NitroWebExpress™ System Shutdown Complete!                        ║"
echo "║                                                                       ║"
echo "║   NEXT STEPS:                                                         ║"
echo "║   • Verify stopped:  bash scripts/status.sh                          ║"
echo "║   • Restart system:  bash scripts/start-all.sh                        ║"
echo "║   • View logs:       tail -f logging/*.log                           ║"
echo "║                                                                       ║"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"
echo ""
