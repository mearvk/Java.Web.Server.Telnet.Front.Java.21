#!/bin/bash
# NitroWebExpress™ — Deploy All Web Modules (Linux)
# Reads web-deploy-config.xml and deploys enabled modules.
# Each module deploy has a 60-second timeout to prevent hangs.
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
timeout 120 bash "$SCRIPT_DIR/setup-all-databases.sh" 2>/dev/null || echo "[WARN] Some databases may need manual setup"

# Patch WEB-INF and check SSL
echo ""
timeout 60 bash "$SCRIPT_DIR/patch-webinf-and-ssl.sh" 2>/dev/null || echo "[WARN] WEB-INF/SSL patch had issues"
echo ""

# Parse enabled modules from XML
ENABLED=$(grep -B5 '<install>true</install>' "$CONFIG" | grep -oP '(?<=<deploy-script>)[^<]+')

PASS=0; FAIL=0
TOTAL_MODULES=$(echo "$ENABLED" | wc -w)
CURRENT_MODULE=0

for SCRIPT in $ENABLED; do
    CURRENT_MODULE=$((CURRENT_MODULE + 1))
    FULL_PATH="$PROJECT_ROOT/$SCRIPT"
    
    # Run setup-db if it exists alongside deploy script
    SETUP_DB="$(dirname "$FULL_PATH")/setup-db.sh"
    if [ -f "$SETUP_DB" ]; then
        timeout 30 bash "$SETUP_DB" 2>/dev/null && echo "  [DB] $(basename "$(dirname "$SETUP_DB")") database ready" || true
    fi
    
    if [ -f "$FULL_PATH" ]; then
        echo ""
        echo "[*] [$CURRENT_MODULE/$TOTAL_MODULES] Deploying: $SCRIPT"
        set +e
        timeout 180 bash "$FULL_PATH" 2>&1
        EXIT_CODE=$?
        set -e
        if [ $EXIT_CODE -eq 0 ]; then
            PASS=$((PASS + 1))
        elif [ $EXIT_CODE -eq 124 ]; then
            echo "[!] TIMEOUT (180s): $SCRIPT — skipping"
            FAIL=$((FAIL + 1))
        else
            echo "[!] Failed (exit $EXIT_CODE): $SCRIPT"
            FAIL=$((FAIL + 1))
        fi
    else
        # Try to create missing script
        if [ -f "$PROJECT_ROOT/scripts/fix-missing-deploy-scripts.sh" ]; then
            bash "$PROJECT_ROOT/scripts/fix-missing-deploy-scripts.sh" 2>/dev/null
            if [ -f "$FULL_PATH" ]; then
                echo "[*] Auto-created, deploying: $SCRIPT"
                DEPLOY_OUT=$(timeout 60 bash "$FULL_PATH" 2>&1)
                EXIT_CODE=$?
                echo "$DEPLOY_OUT" | tail -3
                [ $EXIT_CODE -eq 0 ] && PASS=$((PASS + 1)) || FAIL=$((FAIL + 1))
            else
                echo "[!] Script not found: $FULL_PATH"
                FAIL=$((FAIL + 1))
            fi
        else
            echo "[!] Script not found: $FULL_PATH"
            FAIL=$((FAIL + 1))
        fi
    fi
done

# Tomcat service setup
TOMCAT_HOME=$(grep -oP '(?<=<tomcat-home>)[^<]+' "$CONFIG")
if systemctl list-unit-files | grep -q tomcat; then
    systemctl enable tomcat 2>/dev/null && echo "[*] Tomcat enabled on reboot"
fi

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo " Results: $PASS deployed | $FAIL failed"
echo " Tomcat: systemctl restart tomcat"
echo "═══════════════════════════════════════════════════════════════"

# Quick port verification
echo ""
echo "    Port check:"
for PORT in 20000 9999 49210 49211 49212 49213 49214 8080; do
    if timeout 1 bash -c "echo >/dev/tcp/localhost/$PORT" 2>/dev/null; then
        echo "      port $PORT: UP"
    else
        echo "      port $PORT: --"
    fi
done
echo ""
