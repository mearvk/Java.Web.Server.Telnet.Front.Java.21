#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════════
# NitroWebExpress™ — SpectrumTandem Frontend Shutdown
# Usage: bash shutdown-frontend.sh [tomcat_home]
# ═══════════════════════════════════════════════════════════════════════════════════
set -uo pipefail
MOD_ROOT="$(cd "$(dirname "$0")" && pwd)"
TOMCAT_HOME="${1:-${CATALINA_HOME:-/opt/apache-tomcat-11.0.2}}"
CONTEXT="spectrum-tandem"

echo ""
echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║  SpectrumTandem — Frontend Shutdown                                     ║"
echo "║  Context: /$CONTEXT                                                       ║"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"
echo ""

DEPLOY_DIR="$TOMCAT_HOME/webapps/$CONTEXT"
if [ -d "$DEPLOY_DIR" ]; then
    echo "  [*] Removing $DEPLOY_DIR..."
    rm -rf "$DEPLOY_DIR"
    echo "  [✓] Undeployed"
else
    echo "  [--] Not deployed ($DEPLOY_DIR not found)"
fi

echo ""
echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║  SpectrumTandem Frontend Stopped                                        ║"
echo "║  Restart: bash start-frontend.sh                                          ║"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"
echo ""
