#!/bin/bash
# GrayPortRegistry™ — Deploy + Setup
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
GRAY_ROOT="$(dirname "$SCRIPT_DIR")"
WEBAPP_SRC="$GRAY_ROOT/servlets/servlet/src/main/webapp"
TOMCAT_HOME="${1:-${CATALINA_HOME:-/opt/tomcat}}"
DEPLOY_DIR="$TOMCAT_HOME/webapps/gray-registry"
echo "═══════════════════════════════════════════════════════════════"
echo " GrayPortRegistry™ — Deploy (port 9999)"
echo "═══════════════════════════════════════════════════════════════"
mkdir -p "$DEPLOY_DIR/WEB-INF/lib"
cp -r "$WEBAPP_SRC/"* "$DEPLOY_DIR/"
# JDBC driver
for D in "$(dirname "$GRAY_ROOT")/black/presidential/Brarner.M.Alete/jars" "$GRAY_ROOT/jars"; do
    ls "$D/mysql-connector-j"*.jar &>/dev/null 2>&1 && cp "$D/mysql-connector-j"*.jar "$DEPLOY_DIR/WEB-INF/lib/" && break
done
chown -R tomcat:tomcat "$DEPLOY_DIR" 2>/dev/null || true
# Setup DB
mysql -u root -p'$$Ironman1' -h 127.0.0.1 <<'SQL'
CREATE DATABASE IF NOT EXISTS nwe_gray_registry CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE nwe_gray_registry;
CREATE TABLE IF NOT EXISTS leases (id INT AUTO_INCREMENT PRIMARY KEY, block_id INT NOT NULL, term VARCHAR(20), btc_txid VARCHAR(128), lessee_ip VARCHAR(45), leased_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, expires_at TIMESTAMP NULL, INDEX idx_block(block_id));
CREATE TABLE IF NOT EXISTS bindings (id BIGINT AUTO_INCREMENT PRIMARY KEY, block_id INT NOT NULL, port BIGINT NOT NULL, bound_ip VARCHAR(45), bound_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, INDEX idx_block(block_id));
SQL
echo "[✓] Deployed: http://localhost:8080/gray-registry/"
echo "═══════════════════════════════════════════════════════════════"
