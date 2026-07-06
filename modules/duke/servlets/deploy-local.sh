#!/bin/bash
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TOMCAT_WEBAPPS="${TOMCAT_HOME:-/home/mearvk/tomcat}/webapps"
echo "[*] Deploying DukeUniversity™ to $TOMCAT_WEBAPPS/duke"
rm -rf "$TOMCAT_WEBAPPS/duke"; mkdir -p "$TOMCAT_WEBAPPS/duke"
cp -r "$SCRIPT_DIR/servlet/src/main/webapp/"* "$TOMCAT_WEBAPPS/duke/"
mkdir -p "$TOMCAT_WEBAPPS/duke/WEB-INF/lib"
NWE_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
JDBC_JAR=$(find "$NWE_ROOT/modules/black/presidential/Brarner.M.Alete/jars" "$NWE_ROOT/jars/mysql" -name "mysql-connector-j*.jar" -type f 2>/dev/null | head -1)
[ -n "$JDBC_JAR" ] && cp "$JDBC_JAR" "$TOMCAT_WEBAPPS/duke/WEB-INF/lib/" && echo "[*] JDBC: $(basename "$JDBC_JAR")" || echo "[!] WARNING: mysql-connector-j not found"
if command -v javac &>/dev/null; then
    mkdir -p "$TOMCAT_WEBAPPS/duke/WEB-INF/classes/com/mearvk/duke"
    javac -cp "${TOMCAT_HOME:-/home/mearvk/tomcat}/lib/*" -d "$TOMCAT_WEBAPPS/duke/WEB-INF/classes" "$SCRIPT_DIR/servlet/src/main/java/com/mearvk/duke/"*.java 2>/dev/null || true
fi
echo "[OK] DukeUniversity™ deployed at /duke"
