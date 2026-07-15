#!/bin/bash
set -e
# SAFE: Uses CREATE IF NOT EXISTS. Never drops or overwrites existing data.
# Can be run repeatedly after git pull without risk to production databases.
echo "[*] Creating nwe_library database..."
mysql -u root -e "
CREATE DATABASE IF NOT EXISTS nwe_library;
USE nwe_library;
CREATE TABLE IF NOT EXISTS library_requests (
    id BIGINT AUTO_INCREMENT PRIMARY KEY, title VARCHAR(500) NOT NULL,
    resource_type VARCHAR(100) DEFAULT 'general', status ENUM('pending','found','unavailable') DEFAULT 'pending',
    installer_id VARCHAR(64) DEFAULT NULL, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_type (resource_type), INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS catalog_cache (
    id BIGINT AUTO_INCREMENT PRIMARY KEY, title VARCHAR(500) NOT NULL,
    author VARCHAR(300), collection VARCHAR(200), call_number VARCHAR(50),
    source_url VARCHAR(1000), installer_id VARCHAR(64) DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
"
echo "[OK] nwe_library database ready."
