#!/bin/bash
# Black Beltâ„¢ â€” Deploy + Setup
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BELT_ROOT="$(dirname "$SCRIPT_DIR")"
WEBAPP_SRC="$BELT_ROOT/servlets/servlet/src/main/webapp"
TOMCAT_HOME="${1:-${CATALINA_HOME:-/opt/apache-tomcat-11.0.2}}"
DEPLOY_DIR="$TOMCAT_HOME/webapps/blackbelt"
NWE_ROOT="$(cd "$SCRIPT_DIR/../../.." 2>/dev/null && pwd)"
[ -f "$NWE_ROOT/scripts/deploy-functions.sh" ] && source "$NWE_ROOT/scripts/deploy-functions.sh"
if type nwe_validate_tomcat &>/dev/null; then nwe_validate_tomcat "$TOMCAT_HOME" || exit 1; fi
echo "â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•"
echo " Black Beltâ„¢ â€” Deploy"
echo "â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•"
rm -rf "$DEPLOY_DIR"
mkdir -p "$DEPLOY_DIR/WEB-INF/lib"
cp -r "$WEBAPP_SRC/"* "$DEPLOY_DIR/"
# JDBC driver
JDBC_JAR=$(find "$(dirname "$BELT_ROOT")" -name "mysql-connector-j*.jar" -type f 2>/dev/null | head -1)
[ -z "$JDBC_JAR" ] && JDBC_JAR=$(find "$TOMCAT_HOME/lib" -name "mysql-connector-j*.jar" -type f 2>/dev/null | head -1)
[ -n "$JDBC_JAR" ] && cp "$JDBC_JAR" "$DEPLOY_DIR/WEB-INF/lib/" && echo "[*] MySQL connector: $(basename "$JDBC_JAR")"
chown -R tomcat:tomcat "$DEPLOY_DIR" 2>/dev/null || true
# Setup DB
_NWE="$(cd "$(dirname "$0")/../../.." 2>/dev/null && pwd)"; [ -f "$_NWE/.nwe-credentials" ] && source "$_NWE/.nwe-credentials"; mysql -u "${NWE_DB_USER:-root}" -p"${NWE_DB_PASS:-'$$Ironman1'}"  -h 127.0.0.1 <<'SQL'
CREATE DATABASE IF NOT EXISTS nwe_blackbelt CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE nwe_blackbelt;
CREATE TABLE IF NOT EXISTS questions (id INT AUTO_INCREMENT PRIMARY KEY, question TEXT, answer TEXT, ip VARCHAR(45), asked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, INDEX idx_time(asked_at));
SQL
echo "[âœ“] Deployed: http://localhost:8080/blackbelt/"
echo "â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•"
