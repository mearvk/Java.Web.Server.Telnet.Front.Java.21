#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════════
# NitroWebExpress™ — Chat Database Setup
# Creates nwe_chat database with users, messages, event_log, federation_log,
# ranks, and chat_settings tables.
# SAFE: Uses CREATE IF NOT EXISTS. Never drops or overwrites existing data.
# Installer Tech ID: Max Rupplin
# ═══════════════════════════════════════════════════════════════════════════════════
set -e

echo "[*] Creating nwe_chat database..."

mysql -u root -e "
CREATE DATABASE IF NOT EXISTS nwe_chat;
USE nwe_chat;

CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(64) NOT NULL UNIQUE,
    password_hash VARCHAR(128) NOT NULL,
    salt VARCHAR(64) NOT NULL,
    email VARCHAR(256),
    profile_picture VARCHAR(512),
    resume_path VARCHAR(512),
    ip_address VARCHAR(45),
    last_ip VARCHAR(45),
    geo_city VARCHAR(128) DEFAULT 'Unknown',
    geo_country VARCHAR(128) DEFAULT 'Unknown',
    is_admin BOOLEAN DEFAULT FALSE,
    is_banned BOOLEAN DEFAULT FALSE,
    is_deleted BOOLEAN DEFAULT FALSE,
    federated_connects INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP NULL,
    deleted_at TIMESTAMP NULL,
    INDEX idx_username (username),
    INDEX idx_ip (ip_address),
    INDEX idx_last_ip (last_ip)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS messages (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    sender_id INT NOT NULL,
    receiver_id INT DEFAULT -1,
    content TEXT,
    msg_type ENUM('DM','BROADCAST','FILE','VOICE','SYSTEM') DEFAULT 'DM',
    sender_ip VARCHAR(45),
    sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_sender (sender_id),
    INDEX idx_receiver (receiver_id),
    INDEX idx_sent (sent_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS event_log (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    event_type VARCHAR(128) NOT NULL,
    ip_address VARCHAR(45),
    event_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_user (user_id),
    INDEX idx_event (event_type),
    INDEX idx_time (event_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS federation_log (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    remote_server VARCHAR(256) NOT NULL,
    connected_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_user (user_id),
    INDEX idx_server (remote_server(128))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS ranks (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    rank_name VARCHAR(64) NOT NULL,
    awarded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS chat_settings (
    id INT AUTO_INCREMENT PRIMARY KEY,
    setting_key VARCHAR(128) NOT NULL UNIQUE,
    setting_value TEXT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    updated_by VARCHAR(128) DEFAULT 'system',
    INDEX idx_key (setting_key)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT IGNORE INTO chat_settings (setting_key, setting_value, updated_by) VALUES
    ('session_timeout_hours', '4', 'Max Rupplin'),
    ('max_federation_servers', '5', 'Max Rupplin'),
    ('concealment_3_threshold', '200', 'Max Rupplin'),
    ('gold_cert_threshold', '300', 'Max Rupplin'),
    ('encryption_default', 'DH-2048', 'Max Rupplin'),
    ('max_file_size_mb', '25', 'Max Rupplin'),
    ('max_voice_duration_sec', '120', 'Max Rupplin'),
    ('admin_password', 'NWE_CHAT_ADMIN_2026', 'Max Rupplin'),
    ('ethics_statement', 'We conceal God but do not work for Her.', 'Max Rupplin'),
    ('brand', 'NWE Chat™', 'Max Rupplin');
"

echo "[OK] nwe_chat database ready."
