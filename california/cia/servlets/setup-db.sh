#!/bin/bash
set -e
echo "[*] Creating nwe_california_cia database..."
mysql -u root -e "
CREATE DATABASE IF NOT EXISTS nwe_california_cia;
USE nwe_california_cia;
CREATE TABLE IF NOT EXISTS intelligence_reports (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    category VARCHAR(100) NOT NULL,
    report_text TEXT NOT NULL,
    status ENUM('pending','reviewed','forwarded','closed') DEFAULT 'pending',
    installer_id VARCHAR(64) DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_category (category), INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS foia_requests (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    subject VARCHAR(500) NOT NULL,
    status ENUM('submitted','processing','complete','denied') DEFAULT 'submitted',
    installer_id VARCHAR(64) DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
"
echo "[OK] nwe_california_cia database ready."
