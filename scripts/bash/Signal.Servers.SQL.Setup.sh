#!/usr/bin/env bash
# Signal.Servers.SQL.Setup.sh — create databases and tables for international signal servers
# Databases: nwe_japan, nwe_russia, nwe_mexico, nwe_greece_intl

set -e

MYSQL="sudo mysql"

echo "[SignalServers] Creating signal server databases..."

$MYSQL <<'SQL'

-- ─────────────────────────────────────────────────────────────────────────────
-- nwe_japan (JapanSignalServer™ — port 49201)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE DATABASE IF NOT EXISTS nwe_japan CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE nwe_japan;

CREATE TABLE IF NOT EXISTS japan_signals (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    signal_type     VARCHAR(32) NOT NULL,
    source_id       VARCHAR(64),
    source_url      VARCHAR(512),
    source_port     INT,
    content         LONGTEXT,
    lang            VARCHAR(8) DEFAULT 'ja',
    retrieved_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_type  (signal_type),
    INDEX idx_time  (retrieved_at)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS japan_news (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    source_id       VARCHAR(64),
    category        VARCHAR(32),
    url             VARCHAR(512),
    headline        VARCHAR(512),
    content         LONGTEXT,
    retrieved_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_source (source_id),
    INDEX idx_time  (retrieved_at)
) ENGINE=InnoDB;

CREATE USER IF NOT EXISTS 'nwe'@'localhost' IDENTIFIED BY 'nwe_japan_pass';
GRANT ALL PRIVILEGES ON nwe_japan.* TO 'nwe'@'localhost';

-- ─────────────────────────────────────────────────────────────────────────────
-- nwe_russia (RussiaSignalServer™ — port 49202)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE DATABASE IF NOT EXISTS nwe_russia CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE nwe_russia;

CREATE TABLE IF NOT EXISTS russia_signals (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    signal_type     VARCHAR(32) NOT NULL,
    source_id       VARCHAR(64),
    source_url      VARCHAR(512),
    source_port     INT,
    content         LONGTEXT,
    lang            VARCHAR(8) DEFAULT 'ru',
    retrieved_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_type  (signal_type),
    INDEX idx_time  (retrieved_at)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS russia_news (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    source_id       VARCHAR(64),
    category        VARCHAR(32),
    url             VARCHAR(512),
    headline        VARCHAR(512),
    content         LONGTEXT,
    retrieved_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_source (source_id),
    INDEX idx_time  (retrieved_at)
) ENGINE=InnoDB;

GRANT ALL PRIVILEGES ON nwe_russia.* TO 'nwe'@'localhost';

-- ─────────────────────────────────────────────────────────────────────────────
-- nwe_mexico (MexicoSignalServer™ — port 49203)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE DATABASE IF NOT EXISTS nwe_mexico CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE nwe_mexico;

CREATE TABLE IF NOT EXISTS mexico_signals (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    signal_type     VARCHAR(32) NOT NULL,
    source_id       VARCHAR(64),
    source_url      VARCHAR(512),
    source_port     INT,
    content         LONGTEXT,
    lang            VARCHAR(8) DEFAULT 'es',
    retrieved_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_type  (signal_type),
    INDEX idx_time  (retrieved_at)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS mexico_news (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    source_id       VARCHAR(64),
    category        VARCHAR(32),
    url             VARCHAR(512),
    headline        VARCHAR(512),
    content         LONGTEXT,
    retrieved_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_source (source_id),
    INDEX idx_time  (retrieved_at)
) ENGINE=InnoDB;

GRANT ALL PRIVILEGES ON nwe_mexico.* TO 'nwe'@'localhost';

-- ─────────────────────────────────────────────────────────────────────────────
-- nwe_greece_intl (GreeceInternationalSignalServer™ — port 49204)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE DATABASE IF NOT EXISTS nwe_greece_intl CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE nwe_greece_intl;

CREATE TABLE IF NOT EXISTS greece_intl_signals (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    signal_type     VARCHAR(32) NOT NULL,
    source_id       VARCHAR(64),
    source_url      VARCHAR(512),
    source_port     INT,
    content         LONGTEXT,
    lang            VARCHAR(8) DEFAULT 'el',
    retrieved_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_type  (signal_type),
    INDEX idx_time  (retrieved_at)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS greece_intl_news (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    source_id       VARCHAR(64),
    category        VARCHAR(32),
    url             VARCHAR(512),
    headline        VARCHAR(512),
    content         LONGTEXT,
    retrieved_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_source (source_id),
    INDEX idx_time  (retrieved_at)
) ENGINE=InnoDB;

GRANT ALL PRIVILEGES ON nwe_greece_intl.* TO 'nwe'@'localhost';

FLUSH PRIVILEGES;

SQL

echo "[SignalServers] All signal server databases created."
