#!/bin/bash
# Brarner.M.Alete™ — After-Pull Deploy
# Syncs webapp resources to Tomcat and restarts services only if changed.
# Usage: sudo bash install/after-pull.sh [tomcat_home]
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BMA_ROOT="$(dirname "$SCRIPT_DIR")"
WEBAPP_SRC="$BMA_ROOT/servlets/servlet/src/main/webapp"
TOMCAT_HOME="${1:-${CATALINA_HOME:-/opt/tomcat}}"
CONTEXT="brarner.m.alete"
DEPLOY_DIR="$TOMCAT_HOME/webapps/$CONTEXT"

if [ ! -d "$WEBAPP_SRC" ]; then
    echo "[!] Webapp source not found: $WEBAPP_SRC"; exit 1
fi
if [ ! -d "$DEPLOY_DIR" ]; then
    echo "[!] Deploy dir not found: $DEPLOY_DIR — run install/deploy-local.sh first"; exit 1
fi

# Sync webapp resources, track if anything changed
CHANGED=0

# Sync JSP/XHTML/XML/CSS/images
rsync -rc --out-format="%n" "$WEBAPP_SRC/" "$DEPLOY_DIR/" \
    --exclude="WEB-INF/db.properties" | while read -r f; do
    echo "  [updated] $f"
    CHANGED=1
done

# Check if rsync actually changed files (subshell workaround)
DIFF=$(rsync -rcn --out-format="%n" "$WEBAPP_SRC/" "$DEPLOY_DIR/" --exclude="WEB-INF/db.properties" 2>/dev/null)

if [ -z "$DIFF" ]; then
    echo "[*] No changes detected — deployment is current."
    exit 0
fi

echo "[*] Synced changes to $DEPLOY_DIR"

# Sync JARs if present
JARS_CHANGED=""
if ls "$BMA_ROOT/jars/"*.jar &>/dev/null; then
    JARS_CHANGED=$(rsync -rcn --out-format="%n" "$BMA_ROOT/jars/" "$DEPLOY_DIR/WEB-INF/lib/" 2>/dev/null)
    if [ -n "$JARS_CHANGED" ]; then
        rsync -rc "$BMA_ROOT/jars/" "$DEPLOY_DIR/WEB-INF/lib/"
        echo "[*] JARs updated in WEB-INF/lib/"
    fi
fi

# Fix ownership
chown -R tomcat:tomcat "$DEPLOY_DIR" 2>/dev/null || true

# Determine if restart needed (JARs or web.xml changed require restart; JSP changes don't)
NEEDS_TOMCAT_RESTART=0
if [ -n "$JARS_CHANGED" ]; then
    NEEDS_TOMCAT_RESTART=1
fi
if echo "$DIFF" | grep -q "WEB-INF/web.xml"; then
    NEEDS_TOMCAT_RESTART=1
fi

if [ "$NEEDS_TOMCAT_RESTART" -eq 1 ]; then
    echo "[*] Restarting Tomcat (JARs or web.xml changed)..."
    systemctl restart tomcat 2>/dev/null || "$TOMCAT_HOME/bin/shutdown.sh" && "$TOMCAT_HOME/bin/startup.sh"
    echo "[✓] Tomcat restarted"
else
    echo "[*] JSP/static changes only — Tomcat hot-reloads, no restart needed."
fi

# Restart Apache only if static assets (css/images) changed — clears mod_cache
if echo "$DIFF" | grep -qE "^(css/|images/)"; then
    echo "[*] Reloading Apache2 (static assets changed)..."
    systemctl reload apache2 2>/dev/null || systemctl reload httpd 2>/dev/null || true
    echo "[✓] Apache2 reloaded"
fi

echo "[✓] After-pull deploy complete."
