#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# NitroWebExpress™ — Shutdown All Frontend Modules
# Undeploys all module webapps from Tomcat.
# Usage: bash scripts/shutdown-frontends.sh [tomcat_home] [--stop-tomcat]
# ═══════════════════════════════════════════════════════════════════════════════
set -uo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$PROJECT_ROOT/scripts/print-descriptor.sh" 2>/dev/null || true
TOMCAT_HOME="${1:-${CATALINA_HOME:-/home/mearvk/tomcat}}"
STOP_TOMCAT=false

# Check for --stop-tomcat flag
for arg in "$@"; do
    if [ "$arg" = "--stop-tomcat" ]; then
        STOP_TOMCAT=true
    fi
done

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

FUTURES_SHUTDOWN="red/Futures/shutdown-frontend.sh"

echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║  NitroWebExpress™ — Shutdown All Frontend Modules                        ║"
echo "║  Tomcat: $TOMCAT_HOME                                                     ║"
if [ "$STOP_TOMCAT" = true ]; then
    echo "║  Will STOP Tomcat after undeploying modules                              ║"
fi
echo "╚═══════════════════════════════════════════════════════════════════════════╝"
echo ""

SUCCESS=()
FAILED=()

# Undeploy standard modules
for MODULE_SPEC in "${MODULES[@]}"; do
    IFS=':' read -r MOD_DIR CONTEXT <<< "$MODULE_SPEC"
    MOD_PATH="$PROJECT_ROOT/modules/$MOD_DIR"

    if [ ! -d "$MOD_PATH" ]; then
        continue
    fi

    if [ ! -f "$MOD_PATH/shutdown.sh" ]; then
        continue
    fi

    echo -n "  [*] Undeploying $MOD_DIR ($CONTEXT)... "

    if cd "$MOD_PATH" && bash shutdown.sh "$TOMCAT_HOME" > /dev/null 2>&1; then
        echo "✓"
        SUCCESS+=("$MOD_DIR:$CONTEXT")
    else
        echo "✗"
        FAILED+=("$MOD_DIR:$CONTEXT")
    fi
done

# Undeploy Futures frontend (special convention: -frontend)
if [ -f "$PROJECT_ROOT/modules/$FUTURES_SHUTDOWN" ]; then
    echo -n "  [*] Undeploying Futures (frontend)... "
    if cd "$PROJECT_ROOT/modules/red/Futures" && bash shutdown-frontend.sh "$TOMCAT_HOME" > /dev/null 2>&1; then
        echo "✓"
        SUCCESS+=("Futures:frontend")
    else
        echo "✗"
        FAILED+=("Futures:frontend")
    fi
fi

echo ""

# Optionally stop Tomcat
if [ "$STOP_TOMCAT" = true ]; then
    echo "  [*] Stopping Tomcat..."
    if [ -x "$TOMCAT_HOME/bin/shutdown.sh" ]; then
        "$TOMCAT_HOME/bin/shutdown.sh" > /dev/null 2>&1 || true
        sleep 2
        echo "  [✓] Tomcat stopped"
    else
        sudo systemctl stop tomcat 2>/dev/null || true
        sleep 2
        echo "  [✓] Tomcat stopped"
    fi
fi

echo ""
echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║  Frontend Shutdown Summary                                                ║"
echo "║  Undeployed: ${#SUCCESS[@]} / $(( ${#MODULES[@]} + 1 ))                    ║"
if [ ${#FAILED[@]} -gt 0 ]; then
    echo "║  Failed:     ${#FAILED[@]}                                              ║"
fi
echo "╚═══════════════════════════════════════════════════════════════════════════╝"

[ ${#FAILED[@]} -eq 0 ]

