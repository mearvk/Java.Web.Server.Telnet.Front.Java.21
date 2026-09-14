-- nwe_gray_registry — MySQL schema for Installer ID Tech™ Port Registry
-- Author: Max Rupplin — MEARVK LLC

CREATE DATABASE IF NOT EXISTS nwe_gray_registry
    CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE nwe_gray_registry;

-- Active and historical port block leases
CREATE TABLE IF NOT EXISTS leases (
    id          BIGINT AUTO_INCREMENT PRIMARY KEY,
    block_id    INT NOT NULL,
    term        VARCHAR(20) NOT NULL DEFAULT 'month',
    btc_txid    VARCHAR(128) NOT NULL,
    client_ip   VARCHAR(45) NOT NULL,
    leased_at   DATETIME NOT NULL,
    expires_at  DATETIME NOT NULL,
    active      BOOLEAN DEFAULT TRUE,
    INDEX idx_block (block_id),
    INDEX idx_expires (expires_at),
    INDEX idx_client (client_ip)
) ENGINE=InnoDB;

-- Client connection log
CREATE TABLE IF NOT EXISTS connections (
    id            BIGINT AUTO_INCREMENT PRIMARY KEY,
    ip            VARCHAR(45) NOT NULL,
    domain        VARCHAR(255),
    connected_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    geo           VARCHAR(128),
    bitcoin_addr  VARCHAR(64),
    INDEX idx_ip (ip),
    INDEX idx_time (connected_at)
) ENGINE=InnoDB;

-- Bitcoin/Dash payment records
CREATE TABLE IF NOT EXISTS payments (
    id          BIGINT AUTO_INCREMENT PRIMARY KEY,
    btc_txid    VARCHAR(128) NOT NULL UNIQUE,
    block_id    INT NOT NULL,
    term        VARCHAR(20) NOT NULL,
    client_ip   VARCHAR(45) NOT NULL,
    amount_btc  DECIMAL(18,8),
    amount_usd  DECIMAL(10,2),
    currency    VARCHAR(10) DEFAULT 'BTC',
    paid_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_txid (btc_txid),
    INDEX idx_block (block_id)
) ENGINE=InnoDB;

-- Port block allocation and status
CREATE TABLE IF NOT EXISTS blocks (
    block_id    INT PRIMARY KEY,
    start_port  BIGINT NOT NULL,
    end_port    BIGINT NOT NULL,
    status      ENUM('available','leased','reserved') DEFAULT 'available',
    lease_id    BIGINT,
    INDEX idx_status (status)
) ENGINE=InnoDB;

-- Pre-populate 1000 blocks
DELIMITER //
CREATE PROCEDURE IF NOT EXISTS populate_blocks()
BEGIN
    DECLARE i INT DEFAULT 0;
    WHILE i < 1000 DO
        INSERT IGNORE INTO blocks (block_id, start_port, end_port, status)
        VALUES (i, i * 30000000, (i * 30000000) + 29999999, 'available');
        SET i = i + 1;
    END WHILE;
END //
DELIMITER ;

CALL populate_blocks();
