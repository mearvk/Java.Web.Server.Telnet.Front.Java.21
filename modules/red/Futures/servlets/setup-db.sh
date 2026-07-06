#!/bin/bash
# Futures™ — Setup MySQL Database
# Usage: bash modules/Futures/servlets/setup-db.sh
set -e

DB_USER="root"
DB_PASS='$$Ironman1'
DB_HOST="127.0.0.1"
DB_NAME="nwe_futures"
MYSQL="mysql -u$DB_USER -p$DB_PASS -h$DB_HOST"

echo "═══════════════════════════════════════════════════════════════"
echo " Futures™ — Setup Database"
echo "═══════════════════════════════════════════════════════════════"

$MYSQL <<SQL
CREATE DATABASE IF NOT EXISTS $DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE $DB_NAME;

CREATE TABLE IF NOT EXISTS pipeline_log (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    stage VARCHAR(50) NOT NULL,
    connection_id VARCHAR(64),
    result VARCHAR(20),
    details TEXT,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_stage (stage),
    INDEX idx_result (result)
);

CREATE TABLE IF NOT EXISTS training_runs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    epoch INT,
    loss DECIMAL(10,6),
    accuracy DECIMAL(5,4),
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP NULL,
    model_name VARCHAR(100)
);

CREATE TABLE IF NOT EXISTS safety_events (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    event_type VARCHAR(50) NOT NULL,
    connection_id VARCHAR(64),
    reason TEXT,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_type (event_type)
);
SQL

echo "[✓] Database $DB_NAME ready (pipeline_log, training_runs, safety_events)"
echo "═══════════════════════════════════════════════════════════════"
