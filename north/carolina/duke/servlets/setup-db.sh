#!/bin/bash
set -e
echo "[*] Creating nwe_duke database..."
mysql -u root -e "
CREATE DATABASE IF NOT EXISTS nwe_duke;
USE nwe_duke;
CREATE TABLE IF NOT EXISTS college_queries (
    id BIGINT AUTO_INCREMENT PRIMARY KEY, college VARCHAR(200) NOT NULL,
    query_text TEXT NOT NULL, status ENUM('pending','answered','archived') DEFAULT 'pending',
    installer_id VARCHAR(64) DEFAULT NULL, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_college (college), INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS course_catalog (
    id BIGINT AUTO_INCREMENT PRIMARY KEY, college VARCHAR(200) NOT NULL,
    department VARCHAR(200), course_code VARCHAR(20), title VARCHAR(500), description TEXT,
    installer_id VARCHAR(64) DEFAULT NULL, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
"
echo "[OK] nwe_duke database ready."
