#!/bin/bash
# Gray85 Crème Registry™ — Deploy + Setup
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
GRAY85_ROOT="$(dirname "$SCRIPT_DIR")"
WEBAPP_SRC="$GRAY85_ROOT/servlets/servlet/src/main/webapp"
TOMCAT_HOME="${1:-${CATALINA_HOME:-/home/mearvk/tomcat}}"
DEPLOY_DIR="$TOMCAT_HOME/webapps/gray85-registry"
echo "═══════════════════════════════════════════════════════════════"
echo " Gray85 Crème Registry™ — Deploy (port 10085)"
echo "═══════════════════════════════════════════════════════════════"
rm -rf "$DEPLOY_DIR"
mkdir -p "$DEPLOY_DIR/WEB-INF/lib"
cp -r "$WEBAPP_SRC/"* "$DEPLOY_DIR/"
# JDBC driver
JDBC_JAR=$(find "$(dirname "$GRAY85_ROOT")" -name "mysql-connector-j*.jar" -type f 2>/dev/null | head -1)
[ -z "$JDBC_JAR" ] && JDBC_JAR=$(find "$TOMCAT_HOME/lib" -name "mysql-connector-j*.jar" -type f 2>/dev/null | head -1)
[ -n "$JDBC_JAR" ] && cp "$JDBC_JAR" "$DEPLOY_DIR/WEB-INF/lib/" && echo "[*] MySQL connector: $(basename "$JDBC_JAR")"
chown -R tomcat:tomcat "$DEPLOY_DIR" 2>/dev/null || true
# Setup DB
mysql -u root -p'$$Ironman1' -h 127.0.0.1 <<'SQL'
CREATE DATABASE IF NOT EXISTS nwe_gray85_registry CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE nwe_gray85_registry;
CREATE TABLE IF NOT EXISTS leases (id INT AUTO_INCREMENT PRIMARY KEY, block_id INT NOT NULL, term VARCHAR(20), btc_txid VARCHAR(128), lessee_ip VARCHAR(45), leased_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, expires_at TIMESTAMP NULL, INDEX idx_block(block_id));
CREATE TABLE IF NOT EXISTS bindings (id BIGINT AUTO_INCREMENT PRIMARY KEY, block_id INT NOT NULL, port BIGINT NOT NULL, bound_ip VARCHAR(45), is_creme BOOLEAN DEFAULT FALSE, bound_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, INDEX idx_block(block_id));
CREATE TABLE IF NOT EXISTS creme_unlocks (id INT AUTO_INCREMENT PRIMARY KEY, block_id INT NOT NULL, port_offset INT NOT NULL, hours INT NOT NULL, btc_txid VARCHAR(128), unlocked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, expires_at TIMESTAMP NULL, INDEX idx_block(block_id));
SQL
echo "[✓] Deployed: http://localhost:8080/gray85-registry/"
echo "═══════════════════════════════════════════════════════════════"
