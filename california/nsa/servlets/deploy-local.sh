#!/bin/bash
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TOMCAT_WEBAPPS="${TOMCAT_HOME:-/opt/tomcat}/webapps"
SRC="$SCRIPT_DIR/servlet/src/main/webapp"
echo "[*] Deploying CaliforniaNSA™ to $TOMCAT_WEBAPPS/california-nsa"
rm -rf "$TOMCAT_WEBAPPS/california-nsa"
mkdir -p "$TOMCAT_WEBAPPS/california-nsa"
cp -r "$SRC/"* "$TOMCAT_WEBAPPS/california-nsa/"
if command -v javac &>/dev/null; then
    mkdir -p "$TOMCAT_WEBAPPS/california-nsa/WEB-INF/classes/com/mearvk/nsa"
    javac -cp "${TOMCAT_HOME:-/opt/tomcat}/lib/*" -d "$TOMCAT_WEBAPPS/california-nsa/WEB-INF/classes" \
        "$SCRIPT_DIR/servlet/src/main/java/com/mearvk/nsa/"*.java 2>/dev/null || echo "[!] Servlet compilation skipped"
fi
echo "[OK] CaliforniaNSA™ deployed at /california-nsa"
