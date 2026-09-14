#!/bin/bash
set -e
# SAFE: Uses CREATE IF NOT EXISTS. Never drops or overwrites existing data.
# Can be run repeatedly after git pull without risk to production databases.
echo "[*] Creating nwe_california_nsa database..."
mysql -u root -e "
CREATE DATABASE IF NOT EXISTS nwe_california_nsa;
USE nwe_california_nsa;
CREATE TABLE IF NOT EXISTS cyber_reports (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    category VARCHAR(100) NOT NULL,
    report_text TEXT NOT NULL,
    status ENUM('pending','reviewed','escalated','closed') DEFAULT 'pending',
    installer_id VARCHAR(64) DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_category (category), INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS advisories (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(500) NOT NULL,
    severity ENUM('low','medium','high','critical') DEFAULT 'medium',
    source_url VARCHAR(1000),
    installer_id VARCHAR(64) DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
"
echo "[OK] nwe_california_nsa database ready."
