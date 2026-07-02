#!/bin/bash
# Brarner.M.Alete™ — Deploy Local (macOS)
# Deploys webapp to local Tomcat on macOS.
# Usage: bash install/macos/deploy-local.sh [tomcat_home]
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BMA_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
WEBAPP_SRC="$BMA_ROOT/servlets/servlet/src/main/webapp"
TOMCAT_HOME="${1:-${CATALINA_HOME:-/usr/local/opt/tomcat/libexec}}"
# Homebrew Apple Silicon path fallback
[ ! -d "$TOMCAT_HOME/webapps" ] && TOMCAT_HOME="/opt/homebrew/opt/tomcat/libexec"
CONTEXT="brarner.m.alete"
DEPLOY_DIR="$TOMCAT_HOME/webapps/$CONTEXT"

echo "═══════════════════════════════════════════════════════════════"
echo " Brarner.M.Alete™ — Local Deploy (macOS)"
echo " Target: $DEPLOY_DIR"
echo "═══════════════════════════════════════════════════════════════"

if [ ! -d "$TOMCAT_HOME/webapps" ]; then
    echo "[!] Tomcat not found. Install: brew install tomcat"
    exit 1
fi

rm -rf "$DEPLOY_DIR"
mkdir -p "$DEPLOY_DIR/WEB-INF/lib"
cp -r "$WEBAPP_SRC/"* "$DEPLOY_DIR/"

# Copy MySQL connector
if ls "$BMA_ROOT/lib/mysql-connector-j-"*.jar &>/dev/null; then
    cp "$BMA_ROOT/lib/mysql-connector-j-"*.jar "$DEPLOY_DIR/WEB-INF/lib/"
    echo "[*] MySQL connector copied"
fi

echo ""
echo "[✓] Deployed to: $DEPLOY_DIR"
echo "    URL: http://localhost:8080/$CONTEXT/"
echo "    Start Tomcat: brew services start tomcat"
echo "═══════════════════════════════════════════════════════════════"
