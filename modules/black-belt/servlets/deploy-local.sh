#!/bin/bash
# Black Belt™ — Deploy + Setup
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BELT_ROOT="$(dirname "$SCRIPT_DIR")"
WEBAPP_SRC="$BELT_ROOT/servlets/servlet/src/main/webapp"
TOMCAT_HOME="${1:-${CATALINA_HOME:-/home/mearvk/tomcat}}"
DEPLOY_DIR="$TOMCAT_HOME/webapps/blackbelt"
echo "═══════════════════════════════════════════════════════════════"
echo " Black Belt™ — Deploy"
echo "═══════════════════════════════════════════════════════════════"
rm -rf "$DEPLOY_DIR"
mkdir -p "$DEPLOY_DIR/WEB-INF/lib"
cp -r "$WEBAPP_SRC/"* "$DEPLOY_DIR/"
# JDBC driver
JDBC_JAR=$(find "$(dirname "$BELT_ROOT")" -name "mysql-connector-j*.jar" -type f 2>/dev/null | head -1)
[ -z "$JDBC_JAR" ] && JDBC_JAR=$(find "$TOMCAT_HOME/lib" -name "mysql-connector-j*.jar" -type f 2>/dev/null | head -1)
[ -n "$JDBC_JAR" ] && cp "$JDBC_JAR" "$DEPLOY_DIR/WEB-INF/lib/" && echo "[*] MySQL connector: $(basename "$JDBC_JAR")"
chown -R tomcat:tomcat "$DEPLOY_DIR" 2>/dev/null || true
# Setup DB
mysql -u root -p'$$Ironman1' -h 127.0.0.1 <<'SQL'
CREATE DATABASE IF NOT EXISTS nwe_blackbelt CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE nwe_blackbelt;
CREATE TABLE IF NOT EXISTS questions (id INT AUTO_INCREMENT PRIMARY KEY, question TEXT, answer TEXT, ip VARCHAR(45), asked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, INDEX idx_time(asked_at));
SQL
echo "[✓] Deployed: http://localhost:8080/blackbelt/"
echo "═══════════════════════════════════════════════════════════════"
