#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# NitroWebExpress™ — System Status
# Reports the status of all services (MySQL, backends, frontends).
# Usage: bash scripts/status.sh
# ═══════════════════════════════════════════════════════════════════════════════
set -uo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$PROJECT_ROOT/scripts/print-descriptor.sh" 2>/dev/null || true
source "$PROJECT_ROOT/scripts/detect-mysql.sh" 2>/dev/null || true

echo ""
echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║  NitroWebExpress™ — System Status Report                                  ║"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"
echo ""

# ── MySQL Status ──────────────────────────────────────────────────────────────
echo "MySQL:"
echo "───────────────────────────────────────────────────────────────────────────"
if mysqladmin ping -h "$MYSQL_HOST" -P "$MYSQL_PORT" --silent 2>/dev/null; then
    echo "  [✓] MySQL is running (Host: $MYSQL_HOST, Port: $MYSQL_PORT)"
    DATABASES=$(mysql -h "$MYSQL_HOST" -u mearvk -p'$$Ironman1' -e "SHOW DATABASES;" 2>/dev/null | tail -n +2 | wc -l)
    echo "    Databases: $DATABASES"
else
    echo "  [✗] MySQL is NOT running"
fi
echo ""

# ── Tomcat Status ─────────────────────────────────────────────────────────────
echo "Tomcat / Web Services:"
echo "───────────────────────────────────────────────────────────────────────────"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/ 2>/dev/null || echo "000")

if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "302" ]; then
    echo "  [✓] Tomcat is running (HTTP $HTTP_CODE)"
else
    echo "  [✗] Tomcat is NOT responding (HTTP $HTTP_CODE)"
fi
echo ""

# ── Backend Modules ───────────────────────────────────────────────────────────
echo "Backend Modules (TCP Servers):"
echo "───────────────────────────────────────────────────────────────────────────"

declare -A BACKENDS=(
    ["AE6E66:data/pids/backend.pid"]="AE6E66Main"
    ["cia:data/pids/backend.pid"]="CaliforniaCIAServer"
    ["duke:data/pids/backend.pid"]="DukeUniversityServer"
    ["fbi:data/pids/backend.pid"]="CaliforniaFBIServer"
    ["gray:data/pids/backend.pid"]="GrayPortRegistryServer"
    ["gray.a85:data/pids/backend.pid"]="Gray85PortRegistryServer"
    ["Green.Durham.Grass.and.Herb:data/pids/backend.pid"]="Main"
    ["library:data/pids/backend.pid"]="StanfordLibraryServer"
    ["nsa:data/pids/backend.pid"]="CaliforniaNSAServer"
)

BACKENDS_UP=0
BACKENDS_DOWN=0

for SPEC in "${!BACKENDS[@]}"; do
    IFS=':' read -r MOD_DIR PID_FILE <<< "$SPEC"
    PID_PATH="$PROJECT_ROOT/modules/$MOD_DIR/$PID_FILE"

    if [ -f "$PID_PATH" ]; then
        PID=$(cat "$PID_PATH")
        if kill -0 "$PID" 2>/dev/null; then
            echo "  [✓] $MOD_DIR (PID $PID)"
            BACKENDS_UP=$((BACKENDS_UP + 1))
        else
            echo "  [✗] $MOD_DIR (PID $PID — not running)"
            BACKENDS_DOWN=$((BACKENDS_DOWN + 1))
        fi
    else
        echo "  [--] $MOD_DIR (not started)"
        BACKENDS_DOWN=$((BACKENDS_DOWN + 1))
    fi
done

# Futures backend (special convention)
FUTURES_PID="$PROJECT_ROOT/modules/red/Futures/data/pids/backend.pid"
if [ -f "$FUTURES_PID" ]; then
    PID=$(cat "$FUTURES_PID")
    if kill -0 "$PID" 2>/dev/null; then
        echo "  [✓] Futures (PID $PID)"
        BACKENDS_UP=$((BACKENDS_UP + 1))
    else
        echo "  [✗] Futures (PID $PID — not running)"
        BACKENDS_DOWN=$((BACKENDS_DOWN + 1))
    fi
else
    echo "  [--] Futures (not started)"
    BACKENDS_DOWN=$((BACKENDS_DOWN + 1))
fi

echo "  ──────────────────────────────────"
echo "  Running: $BACKENDS_UP / $(( BACKENDS_UP + BACKENDS_DOWN ))"
echo ""

# ── Frontend Modules ──────────────────────────────────────────────────────────
echo "Frontend Modules (Tomcat Webapps):"
echo "───────────────────────────────────────────────────────────────────────────"

CONTEXTS=(
    "ae6e66"
    "blackbelt"
    "california-cia"
    "california-duke"
    "california-fbi"
    "gray-registry"
    "gray85-registry"
    "gdgh"
    "languages"
    "library"
    "california-nsa"
)

FRONTENDS_UP=0
FRONTENDS_DOWN=0

for CONTEXT in "${CONTEXTS[@]}"; do
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:8080/$CONTEXT/" 2>/dev/null || echo "000")

    if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "302" ]; then
        echo "  [✓] /$CONTEXT (HTTP $HTTP_CODE)"
        FRONTENDS_UP=$((FRONTENDS_UP + 1))
    else
        echo "  [--] /$CONTEXT (HTTP $HTTP_CODE)"
        FRONTENDS_DOWN=$((FRONTENDS_DOWN + 1))
    fi
done

echo "  ──────────────────────────────────"
echo "  Running: $FRONTENDS_UP / $(( FRONTENDS_UP + FRONTENDS_DOWN ))"
echo ""

# ── Overall Summary ───────────────────────────────────────────────────────────
echo ""
echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║  Overall Status                                                          ║"
echo "║  MySQL:          $([ "$HTTP_CODE" != "000" ] && echo "[✓] Running" || echo "[✗] Stopped")  ║"
echo "║  Backends:       [$BACKENDS_UP up] / [$(( BACKENDS_UP + BACKENDS_DOWN )) total]                  ║"
echo "║  Frontends:      [$FRONTENDS_UP up] / [$(( FRONTENDS_UP + FRONTENDS_DOWN )) total]               ║"
echo "║                                                                          ║"
echo "║  Start:          bash scripts/start-all.sh                               ║"
echo "║  Shutdown:       bash scripts/shutdown-all.sh                            ║"
echo "║  View logs:      tail -f logging/*.log                                   ║"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"
echo ""

