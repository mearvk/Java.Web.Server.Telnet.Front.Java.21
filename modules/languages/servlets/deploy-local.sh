#!/bin/bash
# Languages™ — Deploy + Setup
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LANG_ROOT="$(dirname "$SCRIPT_DIR")"
WEBAPP_SRC="$LANG_ROOT/servlets/servlet/src/main/webapp"
TOMCAT_HOME="${1:-${CATALINA_HOME:-/home/mearvk/tomcat}}"
DEPLOY_DIR="$TOMCAT_HOME/webapps/languages"
NWE_ROOT="$(cd "$SCRIPT_DIR/../../.." 2>/dev/null && pwd)"
[ -f "$NWE_ROOT/scripts/deploy-functions.sh" ] && source "$NWE_ROOT/scripts/deploy-functions.sh"
if type nwe_validate_tomcat &>/dev/null; then nwe_validate_tomcat "$TOMCAT_HOME" || exit 1; fi
echo "═══════════════════════════════════════════════════════════════"
echo " Languages™ — Deploy (Violet — Polite Diplomacy)"
echo "═══════════════════════════════════════════════════════════════"
rm -rf "$DEPLOY_DIR"
mkdir -p "$DEPLOY_DIR/WEB-INF/lib"
cp -r "$WEBAPP_SRC/"* "$DEPLOY_DIR/"
# JDBC driver
JDBC_JAR=$(find "$(dirname "$(dirname "$LANG_ROOT")")" -name "mysql-connector-j*.jar" -type f 2>/dev/null | head -1)
[ -z "$JDBC_JAR" ] && JDBC_JAR=$(find "$TOMCAT_HOME/lib" -name "mysql-connector-j*.jar" -type f 2>/dev/null | head -1)
[ -n "$JDBC_JAR" ] && cp "$JDBC_JAR" "$DEPLOY_DIR/WEB-INF/lib/" && echo "[*] MySQL connector: $(basename "$JDBC_JAR")"
chown -R tomcat:tomcat "$DEPLOY_DIR" 2>/dev/null || true
# Setup DB
mysql -u root -p'$$Ironman1' -h 127.0.0.1 <<'SQL'
CREATE DATABASE IF NOT EXISTS nwe_languages CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE nwe_languages;
CREATE TABLE IF NOT EXISTS translations (id INT AUTO_INCREMENT PRIMARY KEY, source_text TEXT, from_lang VARCHAR(10), to_lang VARCHAR(10), result TEXT, ip VARCHAR(45), translated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, INDEX idx_time(translated_at));
SQL
echo "[✓] Deployed: http://localhost:8080/languages/"
echo "═══════════════════════════════════════════════════════════════"
