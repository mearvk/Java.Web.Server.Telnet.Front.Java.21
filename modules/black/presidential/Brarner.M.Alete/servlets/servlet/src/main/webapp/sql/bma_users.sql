-- Brarner.M.Alete™ — User Session & Registration Schema
-- Database: nwe_bma

CREATE DATABASE IF NOT EXISTS nwe_bma;
USE nwe_bma;

CREATE TABLE IF NOT EXISTS bma_users (
    id          BIGINT AUTO_INCREMENT PRIMARY KEY,
    ip_address  VARCHAR(45) NOT NULL,
    display_name VARCHAR(128) NOT NULL,
    user_type   ENUM('guest','registered') NOT NULL DEFAULT 'guest',
    settings    JSON DEFAULT NULL,
    created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_seen   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    expires_at  DATETIME NOT NULL,
    UNIQUE KEY idx_ip (ip_address)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- expires_at set to created_at + 24 hours on insert
-- Application renews by updating last_seen and expires_at on each visit
