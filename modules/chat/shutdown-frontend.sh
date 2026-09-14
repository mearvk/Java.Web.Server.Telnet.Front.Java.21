#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════════
# NitroWebExpress™ — Chat Frontend Shutdown
# Usage: bash shutdown-frontend.sh [tomcat_home]
# ═══════════════════════════════════════════════════════════════════════════════════
set -uo pipefail
MOD_ROOT="$(cd "$(dirname "$0")" && pwd)"
TOMCAT_HOME="${1:-${CATALINA_HOME:-/opt/apache-tomcat-11.0.2}}"
CONTEXT="chat"

echo ""
echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║  NWE Chat™ — Frontend Shutdown                                          ║"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"
echo ""
DEPLOY_DIR="$TOMCAT_HOME/webapps/$CONTEXT"
if [ -d "$DEPLOY_DIR" ]; then
    echo "  [*] Removing $DEPLOY_DIR..."
    rm -rf "$DEPLOY_DIR"
    echo "  [✓] Undeployed"
else
    echo "  [--] Not deployed"
fi
echo ""
