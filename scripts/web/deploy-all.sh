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

# Setup all databases before deploying
echo ""
echo "[*] Setting up all module databases (non-destructive — existing data preserved)..."
bash "$SCRIPT_DIR/setup-all-databases.sh" 2>/dev/null || echo "[WARN] Some databases may need manual setup"

# Patch WEB-INF and check SSL
echo ""
bash "$SCRIPT_DIR/patch-webinf-and-ssl.sh" 2>/dev/null || echo "[WARN] WEB-INF/SSL patch had issues"
echo ""

# Parse enabled modules from XML
MODULES=$(grep -oP '(?<=<deploy-script>)[^<]+' "$CONFIG")
ENABLED=$(grep -B5 '<install>true</install>' "$CONFIG" | grep -oP '(?<=<deploy-script>)[^<]+')

PASS=0; FAIL=0

for SCRIPT in $ENABLED; do
    FULL_PATH="$PROJECT_ROOT/$SCRIPT"
    MODULE_ID=$(basename "$(dirname "$(dirname "$FULL_PATH")")")
    
    # Run setup-db if it exists alongside deploy script
    SETUP_DB="$(dirname "$FULL_PATH")/setup-db.sh"
    if [ -f "$SETUP_DB" ]; then
        bash "$SETUP_DB" 2>/dev/null && echo "  [DB] $(basename "$(dirname "$SETUP_DB")") database ready" || true
    fi
    
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
        # Try to create missing script for nested-repo modules
        if [ -f "$PROJECT_ROOT/scripts/fix-missing-deploy-scripts.sh" ]; then
            bash "$PROJECT_ROOT/scripts/fix-missing-deploy-scripts.sh" 2>/dev/null
            if [ -f "$FULL_PATH" ]; then
                echo "[*] Auto-created missing script, deploying: $SCRIPT"
                bash "$FULL_PATH" 2>&1 | tail -3 && PASS=$((PASS + 1)) || FAIL=$((FAIL + 1))
            else
                echo "[!] Script not found (nested .git repo?): $FULL_PATH"
                FAIL=$((FAIL + 1))
            fi
        else
            echo "[!] Script not found: $FULL_PATH"
            FAIL=$((FAIL + 1))
        fi
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

# ─── Start backend modules (Strernary™, SignalProcessors, all TCP servers) ───
echo ""
echo "[*] Ensuring backend modules are running..."
BACKEND_SCRIPT="$PROJECT_ROOT/scripts/start-backend-modules.sh"
PID_FILE="$PROJECT_ROOT/data/nwe-main.pid"

if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    echo "    Backend already running (PID $(cat "$PID_FILE"))"
else
    if [ -f "$BACKEND_SCRIPT" ]; then
        echo "    Starting NitroWebExpress™ backend (Strernary™ port 20000, all modules)..."
        bash "$BACKEND_SCRIPT" &
        sleep 8
        if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
            echo "    [✓] Backend started (PID $(cat "$PID_FILE"))"
        else
            echo "    [!] Backend may have failed — check: $PROJECT_ROOT/logging/nwe-main.log"
        fi
    else
        echo "    [!] Backend start script not found: $BACKEND_SCRIPT"
    fi
fi

# Quick port verification
echo ""
echo "    Port check:"
for PORT in 20000 9999 49210 49211 49212 49213 49214; do
    if timeout 1 bash -c "echo >/dev/tcp/localhost/$PORT" 2>/dev/null; then
        echo "      port $PORT: UP"
    else
        echo "      port $PORT: --"
    fi
done
echo ""
echo "═══════════════════════════════════════════════════════════════"
