#!/bin/bash
set -e
echo "[*] Creating nwe_uncw database..."
mysql -u root -e "
CREATE DATABASE IF NOT EXISTS nwe_uncw;
USE nwe_uncw;
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY, username VARCHAR(64) NOT NULL UNIQUE,
    password_hash VARCHAR(128) NOT NULL, salt VARCHAR(64) NOT NULL,
    email VARCHAR(256), student_id VARCHAR(32), college VARCHAR(128) DEFAULT 'Computer Science',
    national_id VARCHAR(64), national_id_confirmed BOOLEAN DEFAULT FALSE,
    is_chancellor BOOLEAN DEFAULT FALSE, is_admin BOOLEAN DEFAULT FALSE, is_banned BOOLEAN DEFAULT FALSE,
    file_storage_pref ENUM('DATABASE','FOLDER') DEFAULT 'DATABASE',
    ip_address VARCHAR(45), last_ip VARCHAR(45), chancellor_last_online TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, last_login TIMESTAMP NULL,
    INDEX idx_username (username), INDEX idx_student_id (student_id), INDEX idx_chancellor (is_chancellor)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS messages (
    id BIGINT AUTO_INCREMENT PRIMARY KEY, sender_id INT NOT NULL, receiver_id INT NOT NULL,
    content TEXT, sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_sender (sender_id), INDEX idx_receiver (receiver_id), INDEX idx_sent (sent_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS files (
    id INT AUTO_INCREMENT PRIMARY KEY, owner_id INT NOT NULL,
    filename VARCHAR(256) NOT NULL, file_size BIGINT DEFAULT 0,
    is_audio BOOLEAN DEFAULT FALSE, storage_type ENUM('DATABASE','FOLDER') DEFAULT 'DATABASE',
    file_data LONGTEXT, file_path VARCHAR(512), uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_owner (owner_id), INDEX idx_audio (is_audio)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS file_shares (
    id INT AUTO_INCREMENT PRIMARY KEY, file_id INT NOT NULL,
    owner_id INT NOT NULL, shared_with_id INT NOT NULL, shared_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_file (file_id), INDEX idx_shared_with (shared_with_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS chancellor_notes (
    id INT AUTO_INCREMENT PRIMARY KEY, chancellor_id INT NOT NULL,
    content TEXT NOT NULL, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_chancellor (chancellor_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
"
echo "[OK] nwe_uncw database ready."
