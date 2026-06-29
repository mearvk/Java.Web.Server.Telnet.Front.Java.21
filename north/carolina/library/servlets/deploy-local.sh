#!/bin/bash
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TOMCAT_WEBAPPS="${TOMCAT_HOME:-/opt/tomcat}/webapps"
echo "[*] Deploying StanfordLibrary™ to $TOMCAT_WEBAPPS/stanford-library"
rm -rf "$TOMCAT_WEBAPPS/stanford-library"; mkdir -p "$TOMCAT_WEBAPPS/stanford-library"
cp -r "$SCRIPT_DIR/servlet/src/main/webapp/"* "$TOMCAT_WEBAPPS/stanford-library/"
if command -v javac &>/dev/null; then
    mkdir -p "$TOMCAT_WEBAPPS/stanford-library/WEB-INF/classes/com/mearvk/library"
    javac -cp "${TOMCAT_HOME:-/opt/tomcat}/lib/*" -d "$TOMCAT_WEBAPPS/stanford-library/WEB-INF/classes" "$SCRIPT_DIR/servlet/src/main/java/com/mearvk/library/"*.java 2>/dev/null || true
fi
echo "[OK] StanfordLibrary™ deployed at /stanford-library"
