#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# Futures™ (Democratic ProFront National 1.0) — Frontend Startup
# Deploys the webapp to Tomcat and ensures Tomcat is running.
# Usage: bash start-frontend.sh [tomcat_home]
# ═══════════════════════════════════════════════════════════════
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FUTURES_ROOT="$SCRIPT_DIR"
TOMCAT_HOME="${1:-${CATALINA_HOME:-/opt/tomcat}}"
CONTEXT="futures"

echo "═══════════════════════════════════════════════════════════════"
echo " Futures™ — Frontend Startup"
echo " Context: /$CONTEXT"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# Deploy webapp
bash "$FUTURES_ROOT/servlets/deploy-local.sh" "$TOMCAT_HOME"
echo ""

# Start Tomcat if not running
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/ 2>/dev/null | grep -q "200\|302\|401\|403"; then
    echo "[*] Tomcat already running"
else
    echo "[*] Starting Tomcat..."
    sudo systemctl start tomcat 2>/dev/null || "$TOMCAT_HOME/bin/startup.sh" 2>/dev/null || true
    sleep 3
fi

# Verify
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:8080/$CONTEXT/" 2>/dev/null || echo "000")
if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "302" ]; then
    echo "[✓] Futures™ webapp is UP"
else
    echo "[!] HTTP $HTTP_CODE — webapp may still be loading"
fi
echo "    URL: http://localhost:8080/$CONTEXT/"
echo ""
echo "    Stop: bash shutdown-frontend.sh"
echo "═══════════════════════════════════════════════════════════════"
