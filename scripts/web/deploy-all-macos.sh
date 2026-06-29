#!/bin/bash
# NitroWebExpress™ — Deploy All Web Modules (macOS)
# Reads web-deploy-config.xml and deploys enabled modules.
# Usage: bash scripts/web/deploy-all-macos.sh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
CONFIG="$SCRIPT_DIR/web-deploy-config.xml"

# macOS Tomcat paths (Homebrew)
TOMCAT_HOME="${CATALINA_HOME:-/opt/homebrew/opt/tomcat/libexec}"
[ ! -d "$TOMCAT_HOME/webapps" ] && TOMCAT_HOME="/usr/local/opt/tomcat/libexec"

echo "═══════════════════════════════════════════════════════════════"
echo " NitroWebExpress™ — Deploy All Web Modules (macOS)"
echo " Tomcat: $TOMCAT_HOME"
echo "═══════════════════════════════════════════════════════════════"

if [ ! -f "$CONFIG" ]; then echo "[FAIL] Config not found: $CONFIG"; exit 1; fi
if [ ! -d "$TOMCAT_HOME/webapps" ]; then
    echo "[!] Tomcat not found. Install: brew install tomcat"
    exit 1
fi

ENABLED=$(grep -B5 '<install>true</install>' "$CONFIG" | grep -oP '(?<=<deploy-script>)[^<]+' 2>/dev/null || \
          grep -B5 '<install>true</install>' "$CONFIG" | sed -n 's/.*<deploy-script>\(.*\)<\/deploy-script>.*/\1/p')

PASS=0; FAIL=0
for SCRIPT in $ENABLED; do
    FULL_PATH="$PROJECT_ROOT/$SCRIPT"
    SETUP_DB="$(dirname "$FULL_PATH")/setup-db.sh"
    [ -f "$SETUP_DB" ] && bash "$SETUP_DB" 2>/dev/null || true
    if [ -f "$FULL_PATH" ]; then
        echo "[*] Deploying: $SCRIPT"
        bash "$FULL_PATH" "$TOMCAT_HOME" 2>&1 | tail -2 && PASS=$((PASS + 1)) || FAIL=$((FAIL + 1))
    else
        echo "[!] Not found: $SCRIPT"; FAIL=$((FAIL + 1))
    fi
done

# Start Tomcat on reboot via launchd
if ! launchctl list 2>/dev/null | grep -q tomcat; then
    echo "[*] To start Tomcat on reboot: brew services start tomcat"
fi

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo " Results: $PASS deployed | $FAIL failed"
echo " Start: brew services start tomcat"
echo "═══════════════════════════════════════════════════════════════"
