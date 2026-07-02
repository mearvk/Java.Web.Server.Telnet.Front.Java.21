#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# Brarner.M.Alete™ — Startup Script
# Builds, deploys to Tomcat, and starts the webapp.
# Usage: bash start.sh [tomcat_home]
# ═══════════════════════════════════════════════════════════════
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BMA_ROOT="$SCRIPT_DIR"
TOMCAT_HOME="${1:-${CATALINA_HOME:-/home/mearvk/tomcat}}"
CONTEXT="brarner.m.alete"

echo "═══════════════════════════════════════════════════════════════"
echo " Brarner.M.Alete™ — Startup"
echo " Tomcat: $TOMCAT_HOME"
echo " Context: /$CONTEXT"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# ── 1. Build WAR if sources changed ──────────────────────────────────────────
if [ -f "$BMA_ROOT/build.sh" ]; then
    echo "[*] Building WAR..."
    bash "$BMA_ROOT/build.sh"
    echo ""
fi

# ── 2. Deploy to Tomcat ──────────────────────────────────────────────────────
echo "[*] Deploying to Tomcat..."
bash "$BMA_ROOT/install/deploy-local.sh" "$TOMCAT_HOME"
echo ""

# ── 3. Start Tomcat if not already running ───────────────────────────────────
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/ 2>/dev/null | grep -q "200\|302\|401\|403"; then
    echo "[*] Tomcat already running"
else
    echo "[*] Starting Tomcat..."
    if [ -x "$TOMCAT_HOME/bin/startup.sh" ]; then
        "$TOMCAT_HOME/bin/startup.sh"
        sleep 3
    elif systemctl is-active --quiet tomcat 2>/dev/null; then
        echo "[*] Tomcat service already active"
    else
        sudo systemctl start tomcat 2>/dev/null || "$TOMCAT_HOME/bin/startup.sh" 2>/dev/null || true
        sleep 3
    fi
fi

# ── 4. Verify ────────────────────────────────────────────────────────────────
echo ""
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:8080/$CONTEXT/" 2>/dev/null || echo "000")

if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "302" ]; then
    echo "[✓] Brarner.M.Alete™ is UP"
    echo "    URL: http://localhost:8080/$CONTEXT/"
else
    echo "[!] HTTP $HTTP_CODE — webapp may still be loading"
    echo "    URL: http://localhost:8080/$CONTEXT/"
    echo "    Log: $TOMCAT_HOME/logs/catalina.out"
fi

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo " Stop: bash shutdown.sh"
echo "═══════════════════════════════════════════════════════════════"
