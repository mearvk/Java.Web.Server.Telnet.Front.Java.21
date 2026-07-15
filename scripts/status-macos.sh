#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# NitroWebExpress™ — System Status (macOS)
# Reports the status of all services.
# Usage: bash scripts/status-macos.sh
# ═══════════════════════════════════════════════════════════════════════════════
set -uo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# macOS sed
if command -v gsed &>/dev/null; then SED="gsed"; else SED="sed"; fi

# Resolve TOMCAT_HOME
NWE_CONFIG="$PROJECT_ROOT/configuration/nwe-config.xml"
TOMCAT_HOME=""
if [ -f "$NWE_CONFIG" ]; then
    TOMCAT_HOME=$($SED -n '/<tomcat>/,/<\/tomcat>/p' "$NWE_CONFIG" | grep -o '<install-dir>[^<]*</install-dir>' | $SED 's/<[^>]*>//g' 2>/dev/null)
fi
if [ -z "$TOMCAT_HOME" ] || [ ! -d "$TOMCAT_HOME/webapps" ]; then
    if command -v brew &>/dev/null && brew list tomcat &>/dev/null 2>&1; then
        TOMCAT_HOME="$(brew --prefix tomcat)/libexec"
    elif [ -d "/opt/homebrew/opt/tomcat/libexec" ]; then
        TOMCAT_HOME="/opt/homebrew/opt/tomcat/libexec"
    elif [ -d "/usr/local/opt/tomcat/libexec" ]; then
        TOMCAT_HOME="/usr/local/opt/tomcat/libexec"
    fi
fi

echo ""
echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║  NitroWebExpress™ — System Status Report (macOS)                          ║"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"
echo ""

# ── Brew Services ─────────────────────────────────────────────────────────────
echo "Homebrew Services:"
echo "───────────────────────────────────────────────────────────────────────────"
brew services list 2>/dev/null | grep -E "mysql|tomcat" || echo "  (no brew services found)"
echo ""

# ── MySQL ─────────────────────────────────────────────────────────────────────
echo "MySQL:"
echo "───────────────────────────────────────────────────────────────────────────"
if mysqladmin ping --silent 2>/dev/null; then
    echo "  [OK] MySQL is running"
    [ -f "$PROJECT_ROOT/.nwe-credentials" ] && source "$PROJECT_ROOT/.nwe-credentials"
    DATABASES=$(mysql -u "${NWE_DB_USER:-root}" -p"${NWE_DB_PASS:-}" -e "SHOW DATABASES;" 2>/dev/null | tail -n +2 | wc -l | tr -d ' ')
    echo "    Databases: $DATABASES"
else
    echo "  [!!] MySQL is NOT running"
    echo "    Start: brew services start mysql"
fi
echo ""

# ── Tomcat ────────────────────────────────────────────────────────────────────
echo "Tomcat / Web Services:"
echo "───────────────────────────────────────────────────────────────────────────"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/ 2>/dev/null || echo "000")
if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "302" ]; then
    echo "  [OK] Tomcat is running (HTTP $HTTP_CODE)"
else
    echo "  [!!] Tomcat is NOT responding (HTTP $HTTP_CODE)"
    echo "    Start: brew services start tomcat"
fi
echo "  Tomcat home: ${TOMCAT_HOME:-unknown}"
echo ""

# ── Backend Modules ───────────────────────────────────────────────────────────
echo "Backend Modules (TCP Servers):"
echo "───────────────────────────────────────────────────────────────────────────"

BACKENDS_UP=0
BACKENDS_DOWN=0

# Check NWE Main
PID_FILE="$PROJECT_ROOT/data/nwe-main.pid"
if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE" 2>/dev/null)" 2>/dev/null; then
    echo "  [OK] NWE Main (PID $(cat "$PID_FILE"))"
    BACKENDS_UP=$((BACKENDS_UP + 1))
else
    echo "  [--] NWE Main (not started)"
    BACKENDS_DOWN=$((BACKENDS_DOWN + 1))
fi

# Check key ports via nc
for PORT in 49152 20000 2000 5512 6682 7743 7744 49199; do
    if nc -z localhost "$PORT" 2>/dev/null; then
        echo "  [OK] Port $PORT — listening"
        BACKENDS_UP=$((BACKENDS_UP + 1))
    else
        echo "  [--] Port $PORT — not listening"
        BACKENDS_DOWN=$((BACKENDS_DOWN + 1))
    fi
done

echo "  ──────────────────────────────────"
echo "  Running: $BACKENDS_UP / $((BACKENDS_UP + BACKENDS_DOWN))"
echo ""

# ── Frontend Modules ──────────────────────────────────────────────────────────
echo "Frontend Modules (Tomcat Webapps):"
echo "───────────────────────────────────────────────────────────────────────────"

FRONTENDS_UP=0
FRONTENDS_DOWN=0

for CONTEXT in ae6e66 blackbelt california-cia california-duke california-fbi gray-registry gray85-registry gdgh languages library california-nsa futures brarner.m.alete; do
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:8080/$CONTEXT/" 2>/dev/null || echo "000")
    if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "302" ]; then
        echo "  [OK] /$CONTEXT (HTTP $HTTP_CODE)"
        FRONTENDS_UP=$((FRONTENDS_UP + 1))
    else
        echo "  [--] /$CONTEXT (HTTP $HTTP_CODE)"
        FRONTENDS_DOWN=$((FRONTENDS_DOWN + 1))
    fi
done

echo "  ──────────────────────────────────"
echo "  Running: $FRONTENDS_UP / $((FRONTENDS_UP + FRONTENDS_DOWN))"
echo ""

# ── Summary ───────────────────────────────────────────────────────────────────
echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║  Start:     bash scripts/start-all-macos.sh                              ║"
echo "║  Shutdown:  bash scripts/shutdown-all-macos.sh                            ║"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"
echo ""
