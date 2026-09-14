#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════════
# NitroWebExpress™ — SpectrumTandem Frontend Startup (Legacy)
# Deploys the webapp to Tomcat.
# Usage: bash start.sh [tomcat_home]
# ═══════════════════════════════════════════════════════════════════════════════════
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MOD_ROOT="$SCRIPT_DIR"
PROJECT_ROOT="$(cd "$MOD_ROOT/../.." && pwd)"
TOMCAT_HOME="${1:-${CATALINA_HOME:-/opt/apache-tomcat-11.0.2}}"
CONTEXT="spectrum-tandem"

echo ""
echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║  SpectrumTandem Frontend — Startup                                      ║"
echo "║  Context: /$CONTEXT                                                       ║"
echo "║  Tomcat:  $TOMCAT_HOME                                                    ║"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"
echo ""

# ── 1. Deploy to Tomcat ──────────────────────────────────────────────────────────
echo "  [*] Deploying to Tomcat..."
bash "$MOD_ROOT/servlets/deploy-local.sh" "$TOMCAT_HOME" > /dev/null 2>&1
echo "  [✓] Deployed"
echo ""

# ── 2. Start Tomcat if not already running ───────────────────────────────────────
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/ 2>/dev/null | grep -q "200\|302\|401\|403"; then
    echo "  [✓] Tomcat already running"
else
    echo "  [*] Starting Tomcat..."
    if [ -x "$TOMCAT_HOME/bin/startup.sh" ]; then
        "$TOMCAT_HOME/bin/startup.sh" > /dev/null 2>&1
        sleep 3
    elif systemctl is-active --quiet tomcat 2>/dev/null; then
        echo "  [✓] Tomcat service already active"
    else
        sudo systemctl start tomcat 2>/dev/null || "$TOMCAT_HOME/bin/startup.sh" > /dev/null 2>&1 || true
        sleep 3
    fi
fi

# ── 3. Verify ────────────────────────────────────────────────────────────────────
echo ""
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:8080/$CONTEXT/" 2>/dev/null || echo "000")

if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "302" ]; then
    echo "  [✓] SpectrumTandem Frontend is UP"
    echo "  [✓] URL: http://localhost:8080/$CONTEXT/"
else
    echo "  [--] HTTP $HTTP_CODE — http://localhost:8080/$CONTEXT/"
    echo "  [--] May need a few seconds for Tomcat to deploy"
fi

echo ""
echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║  Manage:                                                                   ║"
echo "║  Stop frontend: bash shutdown-frontend.sh                                 ║"
echo "║  Stop all:      bash shutdown.sh                                           ║"
echo "║  Backend:       bash start-backend.sh                                     ║"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"
echo ""
