#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# NitroWebExpress™ — Start All Frontend Modules
# Deploys all module webapps to Tomcat and verifies HTTP endpoints.
# Usage: bash scripts/start-frontends.sh [tomcat_home]
# ═══════════════════════════════════════════════════════════════════════════════
set -uo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TOMCAT_HOME="${1:-${CATALINA_HOME:-/opt/tomcat}}"
MODULES=(
    "AE6E66:ae6e66"
    "black-belt:blackbelt"
    "cia:california-cia"
    "duke:california-duke"
    "fbi:california-fbi"
    "gray:gray-registry"
    "gray.a85:gray85-registry"
    "Green.Durham.Grass.and.Herb:gdgh"
    "languages:languages"
    "library:library"
    "nsa:california-nsa"
)

FUTURES_FRONTEND="red/Futures/start-frontend.sh"

echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║  NitroWebExpress™ — Start All Frontend Modules                            ║"
echo "║  Tomcat: $TOMCAT_HOME                                                     ║"
echo "║  Modules: ${#MODULES[@]}                                                  ║"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"
echo ""

# Check if Tomcat is configured properly
if [ ! -d "$TOMCAT_HOME" ]; then
    echo "  [ERROR] Tomcat not found at: $TOMCAT_HOME"
    echo "          Set CATALINA_HOME or pass as argument: bash scripts/start-frontends.sh /path/to/tomcat"
    exit 1
fi

echo "  [*] Starting Tomcat if not already running..."
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/ 2>/dev/null | grep -q "200\|302\|401\|403"; then
    echo "  [✓] Tomcat already running"
else
    if [ -x "$TOMCAT_HOME/bin/startup.sh" ]; then
        "$TOMCAT_HOME/bin/startup.sh" > /dev/null 2>&1 &
        sleep 3
    elif systemctl is-active --quiet tomcat 2>/dev/null; then
        echo "  [✓] Tomcat service already active"
    else
        sudo systemctl start tomcat 2>/dev/null || "$TOMCAT_HOME/bin/startup.sh" > /dev/null 2>&1 &
        sleep 3
    fi
fi

echo ""
echo "  [*] Deploying frontend modules..."
echo ""

FAILED=()
SUCCESS=()

# Deploy standard modules
for MODULE_SPEC in "${MODULES[@]}"; do
    IFS=':' read -r MOD_DIR CONTEXT <<< "$MODULE_SPEC"
    MOD_PATH="$PROJECT_ROOT/modules/$MOD_DIR"

    if [ ! -d "$MOD_PATH" ]; then
        echo "  [SKIP] $MOD_DIR — directory not found"
        continue
    fi

    if [ ! -f "$MOD_PATH/start.sh" ]; then
        echo "  [SKIP] $MOD_DIR — no start.sh script"
        continue
    fi

    echo -n "  [*] Starting $MOD_DIR ($CONTEXT)... "

    if cd "$MOD_PATH" && bash start.sh "$TOMCAT_HOME" > /dev/null 2>&1; then
        echo "✓"
        SUCCESS+=("$MOD_DIR:$CONTEXT")
    else
        echo "✗"
        FAILED+=("$MOD_DIR:$CONTEXT")
    fi
done

# Deploy Futures frontend (special convention: -frontend)
if [ -f "$PROJECT_ROOT/modules/$FUTURES_FRONTEND" ]; then
    echo -n "  [*] Starting Futures (frontend)... "
    if cd "$PROJECT_ROOT/modules/red/Futures" && bash start-frontend.sh "$TOMCAT_HOME" > /dev/null 2>&1; then
        echo "✓"
        SUCCESS+=("Futures:frontend")
    else
        echo "✗"
        FAILED+=("Futures:frontend")
    fi
fi

echo ""
echo "  [*] Waiting for webapps to stabilize (10s)..."
sleep 10

# Verify HTTP endpoints
echo "  [*] Verifying HTTP endpoints..."
echo ""

for MODULE_SPEC in "${MODULES[@]}"; do
    IFS=':' read -r MOD_DIR CONTEXT <<< "$MODULE_SPEC"
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:8080/$CONTEXT/" 2>/dev/null || echo "000")

    if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "302" ]; then
        echo "  [✓] /$CONTEXT (HTTP $HTTP_CODE)"
    else
        echo "  [--] /$CONTEXT (HTTP $HTTP_CODE — loading or unavailable)"
    fi
done

echo ""
echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║  Frontend Deployment Summary                                              ║"
echo "║  Success: ${#SUCCESS[@]} / $(( ${#MODULES[@]} + 1 ))                       ║"
if [ ${#FAILED[@]} -gt 0 ]; then
    echo "║  Failed:  ${#FAILED[@]}                                                 ║"
fi
echo "║  Tomcat:  http://localhost:8080                                           ║"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"

if [ ${#FAILED[@]} -gt 0 ]; then
    exit 1
fi

