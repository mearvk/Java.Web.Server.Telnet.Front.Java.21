#!/bin/bash
# CaliforniaFBI™ — Setup MySQL database
set -e
echo "[*] Creating nwe_california_fbi database..."

mysql -u root -e "
CREATE DATABASE IF NOT EXISTS nwe_california_fbi;
USE nwe_california_fbi;

CREATE TABLE IF NOT EXISTS crime_reports (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    category VARCHAR(100) NOT NULL,
    report_text TEXT NOT NULL,
    status ENUM('pending','forwarded','closed') DEFAULT 'pending',
    installer_id VARCHAR(64) DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_category (category),
    INDEX idx_status (status),
    INDEX idx_created (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS fbi_forwarded_tips (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    report_id BIGINT NOT NULL,
    forwarded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    response_code INT,
    installer_id VARCHAR(64) NOT NULL,
    FOREIGN KEY (report_id) REFERENCES crime_reports(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
"

echo "[OK] nwe_california_fbi database ready."
