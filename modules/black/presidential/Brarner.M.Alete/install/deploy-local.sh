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

# Copy MySQL connector if available
if ls "$BMA_ROOT/lib/mysql-connector-j-"*.jar &>/dev/null; then
    cp "$BMA_ROOT/lib/mysql-connector-j-"*.jar "$DEPLOY_DIR/WEB-INF/lib/"
    echo "[*] MySQL connector JAR copied to WEB-INF/lib/"
fi

# Compile servlets if javac available and sources exist
SERVLET_SRC="$BMA_ROOT/servlets/servlet/src/main/java"
if [ -d "$SERVLET_SRC" ] && command -v javac &>/dev/null; then
    echo "[*] Compiling servlet classes..."
    find "$SERVLET_SRC" -name "*.java" > /tmp/bma-sources.txt
    if [ -s /tmp/bma-sources.txt ]; then
        CP="$DEPLOY_DIR/WEB-INF/lib/*"
        # Add Jakarta Servlet API from lib if present
        [ -d "$BMA_ROOT/lib" ] && CP="$BMA_ROOT/lib/*:$CP"
        javac -d "$DEPLOY_DIR/WEB-INF/classes" -cp "$CP" @/tmp/bma-sources.txt 2>/dev/null && \
            echo "[*] Servlets compiled" || \
            echo "[!] Servlet compilation failed (JSP pages still work without servlets)"
        rm -f /tmp/bma-sources.txt
    fi
fi

# Fix ownership
chown -R tomcat:tomcat "$DEPLOY_DIR" 2>/dev/null || true

echo ""
echo "[✓] Deployed to: $DEPLOY_DIR"
echo ""
echo "    JSP:   index.jsp, species.jsp, postal.jsp, art.jsp, science.jsp, status.jsp"
echo "    XHTML: index.xhtml, species.xhtml, postal.xhtml, art.xhtml, science.xhtml, status.xhtml"
echo "    DB:    WEB-INF/db.properties"
echo ""
echo "    URL:   http://localhost:8080/$CONTEXT/"
echo ""
echo "    If Tomcat is running, pages are available immediately."
echo "    Otherwise: sudo systemctl start tomcat"
echo "═══════════════════════════════════════════════════════════════"
