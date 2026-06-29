#!/bin/bash
# Strernary™ — Deploy + Setup
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
STRN_ROOT="$(dirname "$SCRIPT_DIR")"
WEBAPP_SRC="$STRN_ROOT/servlets/servlet/src/main/webapp"
TOMCAT_HOME="${1:-${CATALINA_HOME:-/opt/tomcat}}"
DEPLOY_DIR="$TOMCAT_HOME/webapps/strernary"
echo "═══════════════════════════════════════════════════════════════"
echo " Strernary™ — Deploy (port 20000 inference, web UI)"
echo "═══════════════════════════════════════════════════════════════"
mkdir -p "$DEPLOY_DIR/WEB-INF/lib"
cp -r "$WEBAPP_SRC/"* "$DEPLOY_DIR/"
# JDBC driver
BMA_JARS="$(find "$(dirname "$(dirname "$STRN_ROOT")")" -path "*/Brarner.M.Alete/jars" -type d 2>/dev/null | head -1)"
[ -n "$BMA_JARS" ] && ls "$BMA_JARS/mysql-connector-j"*.jar &>/dev/null && cp "$BMA_JARS/mysql-connector-j"*.jar "$DEPLOY_DIR/WEB-INF/lib/"
chown -R tomcat:tomcat "$DEPLOY_DIR" 2>/dev/null || true
# Setup DB
mysql -u root -p'$$Ironman1' -h 127.0.0.1 <<'SQL'
CREATE DATABASE IF NOT EXISTS nwe_strernary CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE nwe_strernary;
CREATE TABLE IF NOT EXISTS queries (id INT AUTO_INCREMENT PRIMARY KEY, question TEXT, answer TEXT, layer VARCHAR(20), ip VARCHAR(45), asked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, INDEX idx_time(asked_at), INDEX idx_layer(layer));
SQL
echo "[✓] Deployed: http://localhost:8080/strernary/"
echo "═══════════════════════════════════════════════════════════════"
