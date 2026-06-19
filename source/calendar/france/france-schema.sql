-- ═══════════════════════════════════════════════════════════════════
-- nwe_calendar_france — Database schema for CalendarFrance™ module
-- MEARVK LLC — NitroWebExpress™
-- Author: Max Rupplin
-- Date: June 19 2026
-- ═══════════════════════════════════════════════════════════════════

CREATE DATABASE IF NOT EXISTS nwe_calendar_france;
USE nwe_calendar_france;

-- Primary entries table: sources, signals, and internet content from France
CREATE TABLE IF NOT EXISTS france_entries (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    date_ordinal INT NOT NULL,
    year INT NOT NULL,
    category VARCHAR(64),
    source_url VARCHAR(512),
    source_port INT,
    signal_type VARCHAR(64),
    content LONGTEXT,
    aes2_hash VARCHAR(128),
    convergence_score DOUBLE,
    region VARCHAR(64) DEFAULT 'france',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_date (year, date_ordinal),
    INDEX idx_category (category),
    INDEX idx_signal (signal_type),
    INDEX idx_region (region)
);

-- Signal registry: tracks active French signal endpoints
CREATE TABLE IF NOT EXISTS france_signals (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    signal_name VARCHAR(128) NOT NULL,
    signal_type VARCHAR(64) NOT NULL,
    endpoint_url VARCHAR(512) NOT NULL,
    port INT DEFAULT 443,
    last_contacted TIMESTAMP,
    status VARCHAR(32) DEFAULT 'ACTIVE',
    response_time_ms INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_signal_type (signal_type),
    INDEX idx_status (status)
);

-- Source catalog: registered French internet sources
CREATE TABLE IF NOT EXISTS france_sources (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    source_id VARCHAR(64) NOT NULL UNIQUE,
    source_name VARCHAR(256),
    url VARCHAR(512) NOT NULL,
    category VARCHAR(64),
    signal_type VARCHAR(64),
    reliability_score DOUBLE DEFAULT 1.0,
    active BOOLEAN DEFAULT TRUE,
    last_fetch TIMESTAMP,
    fetch_count BIGINT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_source_id (source_id),
    INDEX idx_active (active)
);

-- Convergence log: records convergent field matches from French data
CREATE TABLE IF NOT EXISTS france_convergence_log (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    entry_id BIGINT NOT NULL,
    aes_index INT,
    calendar_index INT,
    aes_value INT,
    calendar_value INT,
    probability DOUBLE,
    classification VARCHAR(32),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (entry_id) REFERENCES france_entries(id),
    INDEX idx_classification (classification),
    INDEX idx_probability (probability)
);

GRANT ALL PRIVILEGES ON nwe_calendar_france.* TO 'nwe'@'localhost';
FLUSH PRIVILEGES;
