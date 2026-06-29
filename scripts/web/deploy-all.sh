#!/bin/bash
# NitroWebExpress™ — Deploy All Web Modules (Linux)
# Reads web-deploy-config.xml and deploys enabled modules.
# Usage: sudo bash scripts/web/deploy-all.sh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
CONFIG="$SCRIPT_DIR/web-deploy-config.xml"

echo "═══════════════════════════════════════════════════════════════"
echo " NitroWebExpress™ — Deploy All Web Modules (Linux)"
echo " Config: $CONFIG"
echo " Root:   $PROJECT_ROOT"
echo "═══════════════════════════════════════════════════════════════"

if [ ! -f "$CONFIG" ]; then
    echo "[FAIL] Config not found: $CONFIG"; exit 1
fi

# Parse enabled modules from XML
MODULES=$(grep -oP '(?<=<deploy-script>)[^<]+' "$CONFIG")
ENABLED=$(grep -B5 '<install>true</install>' "$CONFIG" | grep -oP '(?<=<deploy-script>)[^<]+')

PASS=0; FAIL=0

for SCRIPT in $ENABLED; do
    FULL_PATH="$PROJECT_ROOT/$SCRIPT"
    MODULE_ID=$(basename "$(dirname "$(dirname "$FULL_PATH")")")
    
    # Check if module is enabled
    MODULE_BLOCK=$(grep -A2 "$SCRIPT" "$CONFIG" | head -5)
    
    if [ -f "$FULL_PATH" ]; then
        echo ""
        echo "[*] Deploying: $SCRIPT"
        if bash "$FULL_PATH" 2>&1 | tail -3; then
            PASS=$((PASS + 1))
        else
            echo "[!] Failed: $SCRIPT"
            FAIL=$((FAIL + 1))
        fi
    else
        echo "[!] Script not found: $FULL_PATH"
        FAIL=$((FAIL + 1))
    fi
done

# Setup Tomcat to start on reboot
TOMCAT_HOME=$(grep -oP '(?<=<tomcat-home>)[^<]+' "$CONFIG")
if systemctl list-unit-files | grep -q tomcat; then
    systemctl enable tomcat 2>/dev/null && echo "[*] Tomcat enabled on reboot"
fi

# Setup cron jobs for modules that have cron enabled
echo ""
echo "[*] Configuring cron jobs..."
CRON_MODULES=$(grep -B10 '<cron enabled="true"' "$CONFIG" | grep -oP '(?<=<module id=")[^"]+')
for MOD in $CRON_MODULES; do
    SCHEDULE=$(grep -A15 "id=\"$MOD\"" "$CONFIG" | grep -oP '(?<=schedule=")[^"]+')
    if [ -n "$SCHEDULE" ]; then
        CRON_LINE="$SCHEDULE root cd $PROJECT_ROOT && bash scripts/web/run-module.sh $MOD"
        echo "$CRON_LINE" > "/etc/cron.d/nwe-$MOD" 2>/dev/null || true
        echo "  [OK] $MOD: $SCHEDULE"
    fi
done

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo " Results: $PASS deployed | $FAIL failed"
echo " Tomcat: systemctl restart tomcat"
echo "═══════════════════════════════════════════════════════════════"
