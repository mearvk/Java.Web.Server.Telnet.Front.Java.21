#!/bin/bash
# Brarner.M.Alete™ — Quick Local Deploy (exploded, no WAR)
# Copies webapp directly to Tomcat webapps for immediate serving.
# Usage: sudo bash install/deploy-local.sh [tomcat_home]
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BMA_ROOT="$(dirname "$SCRIPT_DIR")"
WEBAPP_SRC="$BMA_ROOT/servlets/servlet/src/main/webapp"
TOMCAT_HOME="${1:-${CATALINA_HOME:-/opt/tomcat}}"
CONTEXT="brarner.m.alete"
DEPLOY_DIR="$TOMCAT_HOME/webapps/$CONTEXT"

echo "═══════════════════════════════════════════════════════════════"
echo " Brarner.M.Alete™ — Quick Local Deploy"
echo " Source:  $WEBAPP_SRC"
echo " Target:  $DEPLOY_DIR"
echo "═══════════════════════════════════════════════════════════════"

if [ ! -d "$WEBAPP_SRC" ]; then
    echo "[!] Webapp source not found: $WEBAPP_SRC"
    exit 1
fi

if [ ! -d "$TOMCAT_HOME/webapps" ]; then
    echo "[!] Tomcat not found at: $TOMCAT_HOME"
    echo "    Set CATALINA_HOME or pass path: sudo bash install/deploy-local.sh /path/to/tomcat"
    exit 1
fi

# Deploy exploded webapp
echo "[*] Deploying exploded webapp..."
rm -rf "$DEPLOY_DIR"
mkdir -p "$DEPLOY_DIR/WEB-INF/classes" "$DEPLOY_DIR/WEB-INF/lib"
cp -r "$WEBAPP_SRC/"* "$DEPLOY_DIR/"

# Copy JARs from jars/ directory (preferred) or lib/
if ls "$BMA_ROOT/jars/"*.jar &>/dev/null; then
    cp "$BMA_ROOT/jars/"*.jar "$DEPLOY_DIR/WEB-INF/lib/"
    echo "[*] JARs copied from jars/ to WEB-INF/lib/"
elif ls "$BMA_ROOT/lib/"*.jar &>/dev/null; then
    cp "$BMA_ROOT/lib/"*.jar "$DEPLOY_DIR/WEB-INF/lib/"
    echo "[*] JARs copied from lib/ to WEB-INF/lib/"
fi

# Ensure db.properties exists — prompt if missing
DB_PROPS="$DEPLOY_DIR/WEB-INF/db.properties"
if [ ! -f "$DB_PROPS" ] || ! grep -q "db.password=." "$DB_PROPS" 2>/dev/null; then
    echo ""
    echo "[*] db.properties needs MySQL credentials for JSP pages."
    read -rp "    MySQL user [root]: " DB_USER
    DB_USER="${DB_USER:-root}"
    read -rsp "    MySQL password: " DB_PASS
    echo ""
    read -rp "    MySQL host [localhost]: " DB_HOST
    DB_HOST="${DB_HOST:-localhost}"
    read -rp "    MySQL port [3306]: " DB_PORT
    DB_PORT="${DB_PORT:-3306}"
    cat > "$DB_PROPS" <<EOF
# BMA Database Configuration — written by deploy-local.sh
db.driver=com.mysql.cj.jdbc.Driver
db.url=jdbc:mysql://${DB_HOST}:${DB_PORT}/BrarnerScience
db.user=${DB_USER}
db.password=${DB_PASS}
EOF
    chmod 600 "$DB_PROPS"
    echo "[*] db.properties written"
else
    echo "[*] db.properties present (user=$(grep '^db.user=' "$DB_PROPS" | cut -d= -f2-))"
fi

# Compile servlets if javac available and sources exist
SERVLET_SRC="$BMA_ROOT/servlets/servlet/src/main/java"
if [ -d "$SERVLET_SRC" ] && command -v javac &>/dev/null; then
    echo "[*] Compiling servlet classes..."
    find "$SERVLET_SRC" -name "*.java" > /tmp/bma-sources.txt
    if [ -s /tmp/bma-sources.txt ]; then
        CP="$DEPLOY_DIR/WEB-INF/lib/*"
        javac -d "$DEPLOY_DIR/WEB-INF/classes" -cp "$CP" @/tmp/bma-sources.txt 2>/dev/null && \
            echo "[*] Servlets compiled" || \
            echo "[!] Servlet compilation failed (JSP pages still work without servlets)"
        rm -f /tmp/bma-sources.txt
    fi
fi

# Fix ownership
chown -R tomcat:tomcat "$DEPLOY_DIR" 2>/dev/null || true

# Create www and web symlinks in BMA project root → canonical deploy dir
ln -sfn "$DEPLOY_DIR" "$BMA_ROOT/www"
ln -sfn "$DEPLOY_DIR" "$BMA_ROOT/web"
echo "[*] Symlinks: www → $DEPLOY_DIR, web → $DEPLOY_DIR"

echo ""
echo "[✓] Deployed to: $DEPLOY_DIR"
echo ""
JSP_LIST=$(find "$WEBAPP_SRC" -maxdepth 1 -name "*.jsp" -printf "%f " 2>/dev/null | sort)
echo "    JSP:  ${JSP_LIST}"
echo "    DB:   WEB-INF/db.properties"
echo "    URL:  http://localhost:8080/$CONTEXT/"
echo ""
echo "    If Tomcat is running, pages are available immediately."
echo "    Otherwise: sudo systemctl start tomcat"
echo "═══════════════════════════════════════════════════════════════"
