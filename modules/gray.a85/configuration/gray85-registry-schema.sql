-- nwe_gray85_registry — MySQL schema for Installer ID Tech™ Gray.85 Crème Port Registry
-- 15/100 ports Crème-locked (planetary clean, auditor-controlled)
-- Unlockable for $1000 USD donation, 1 hour minimum
-- Author: Max Rupplin — MEARVK LLC

CREATE DATABASE IF NOT EXISTS nwe_gray85_registry
    CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE nwe_gray85_registry;

-- Standard port block leases (85% open ports)
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

-- Crème unlock events — $1000+ donations
CREATE TABLE IF NOT EXISTS creme_unlocks (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    block_id        INT NOT NULL,
    port_offset     INT NOT NULL COMMENT 'Offset within the Crème 15% range',
    btc_txid        VARCHAR(128) NOT NULL,
    client_ip       VARCHAR(45) NOT NULL,
    donation_usd    DECIMAL(10,2) NOT NULL,
    duration_hours  INT NOT NULL DEFAULT 1,
    unlocked_at     DATETIME NOT NULL,
    expires_at      DATETIME NOT NULL,
    active          BOOLEAN DEFAULT TRUE,
    INDEX idx_block (block_id),
    INDEX idx_expires (expires_at),
    INDEX idx_txid (btc_txid)
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
    payment_type ENUM('lease','creme_unlock') NOT NULL DEFAULT 'lease',
    client_ip   VARCHAR(45) NOT NULL,
    amount_btc  DECIMAL(18,8),
    amount_usd  DECIMAL(10,2),
    currency    VARCHAR(10) DEFAULT 'BTC',
    paid_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_txid (btc_txid),
    INDEX idx_block (block_id),
    INDEX idx_type (payment_type)
) ENGINE=InnoDB;

-- Port block allocation with Crème status
CREATE TABLE IF NOT EXISTS blocks (
    block_id        INT PRIMARY KEY,
    start_port      BIGINT NOT NULL,
    end_port        BIGINT NOT NULL,
    open_ports      INT NOT NULL DEFAULT 25500000 COMMENT '85% of 30M',
    creme_ports     INT NOT NULL DEFAULT 4500000 COMMENT '15% of 30M — locked',
    status          ENUM('available','leased','reserved') DEFAULT 'available',
    lease_id        BIGINT,
    INDEX idx_status (status)
) ENGINE=InnoDB;

-- Pre-populate 1000 blocks
DELIMITER //
CREATE PROCEDURE IF NOT EXISTS populate_gray85_blocks()
BEGIN
    DECLARE i INT DEFAULT 0;
    WHILE i < 1000 DO
        INSERT IGNORE INTO blocks (block_id, start_port, end_port, open_ports, creme_ports, status)
        VALUES (i, i * 30000000, (i * 30000000) + 29999999, 25500000, 4500000, 'available');
        SET i = i + 1;
    END WHILE;
END //
DELIMITER ;

CALL populate_gray85_blocks();
