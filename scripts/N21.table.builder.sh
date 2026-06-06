#!/usr/bin/env bash
# N21.table.builder.sh — create database N21 and all application tables

set -e

MYSQL="sudo mysql"

echo "[N21] Creating database N21..."

$MYSQL <<'SQL'

-- ─────────────────────────────────────────────────────────────────────────────
-- Database
-- ─────────────────────────────────────────────────────────────────────────────
CREATE DATABASE IF NOT EXISTS N21
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE N21;

-- ─────────────────────────────────────────────────────────────────────────────
-- Connections  (source/connections/Connection.java)
-- remote_address, internet_address, inception_date, telnet flag
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS connections (
    id                          BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    remote_address              VARCHAR(255)    NOT NULL,
    internet_address            VARCHAR(45)     NOT NULL,   -- IPv4 or IPv6
    server_port                 SMALLINT UNSIGNED NOT NULL,
    is_telnet_excelsior_connected TINYINT(1)    NOT NULL DEFAULT 0,
    inception_date              DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    closed_date                 DATETIME        NULL,
    INDEX idx_remote            (remote_address),
    INDEX idx_inception         (inception_date)
) ENGINE=InnoDB;

-- ─────────────────────────────────────────────────────────────────────────────
-- Geo locations  (ConnectionStatusServer.fetchGeo / ip-api.com)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS geo_locations (
    id                          BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    ip_address                  VARCHAR(45)     NOT NULL,
    city                        VARCHAR(128)    NOT NULL DEFAULT '',
    country                     VARCHAR(128)    NOT NULL DEFAULT '',
    resolved_at                 DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_ip            (ip_address),
    INDEX idx_country           (country)
) ENGINE=InnoDB;

-- ─────────────────────────────────────────────────────────────────────────────
-- Exceptions  (source/exceptions/ExceptionRecord.java)
-- exception type, message, origin class/method, full stack trace, timestamp
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS exceptions (
    id                          BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    exception_type              VARCHAR(255)    NOT NULL,
    message                     TEXT            NULL,
    origin                      VARCHAR(1024)   NOT NULL,
    stack_trace                 MEDIUMTEXT      NOT NULL,
    is_security_event           TINYINT(1)      NOT NULL DEFAULT 0,
    recorded_at                 DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_type              (exception_type),
    INDEX idx_security          (is_security_event),
    INDEX idx_recorded          (recorded_at)
) ENGINE=InnoDB;

-- ─────────────────────────────────────────────────────────────────────────────
-- Security events  (source/exceptions/SecurityExceptionHandler.java)
-- subset of exceptions flagged as security-relevant, with alert metadata
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS security_events (
    id                          BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    exception_id                BIGINT UNSIGNED NULL,
    event_type                  VARCHAR(128)    NOT NULL,   -- SecurityException / auth / access / unauthorized
    message                     TEXT            NULL,
    origin                      VARCHAR(1024)   NOT NULL,
    source_ip                   VARCHAR(45)     NULL,
    alert_triggered             TINYINT(1)      NOT NULL DEFAULT 0,
    recorded_at                 DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY fk_sec_exc      (exception_id) REFERENCES exceptions(id) ON DELETE SET NULL,
    INDEX idx_event_type        (event_type),
    INDEX idx_source_ip         (source_ip),
    INDEX idx_recorded          (recorded_at)
) ENGINE=InnoDB;

-- ─────────────────────────────────────────────────────────────────────────────
-- National IDs  (source/national/NationalID.java)
-- 8-digit public ID + 16-digit private key, linked to a user
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS national_ids (
    id                          BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    eight_digit_id              BIGINT UNSIGNED NOT NULL,
    sixteen_digit_key           BIGINT UNSIGNED NOT NULL,
    issued_at                   DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_eight         (eight_digit_id),
    UNIQUE KEY uq_sixteen       (sixteen_digit_key)
) ENGINE=InnoDB;

-- ─────────────────────────────────────────────────────────────────────────────
-- National Finance IDs  (source/national/NationalFinanceID.java)
-- Full person-aspect profile populated from the initial Telnet connection
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS national_finance_ids (
    id                          BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    national_id                 BIGINT UNSIGNED NOT NULL,
    remote_address              VARCHAR(45)     NOT NULL DEFAULT '',
    iq                          SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    education_level             VARCHAR(128)    NOT NULL DEFAULT '',
    social_skills               TINYINT UNSIGNED NOT NULL DEFAULT 0,   -- 0-100
    equipment                   TEXT            NULL,
    trust_level                 TINYINT UNSIGNED NOT NULL DEFAULT 0,   -- 0-100
    parent_one                  VARCHAR(255)    NOT NULL DEFAULT '',
    parent_two                  VARCHAR(255)    NOT NULL DEFAULT '',
    suspects                    TEXT            NULL,    -- probable beliefs / societal settings
    social_spotting             TEXT            NULL,    -- perceived social placement
    promissory_note             DECIMAL(18,2)   NOT NULL DEFAULT 0.00, -- projected profit value
    created_at                  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY fk_nfid_nat     (national_id)  REFERENCES national_ids(eight_digit_id) ON DELETE CASCADE,
    INDEX idx_national_id       (national_id),
    INDEX idx_trust             (trust_level),
    INDEX idx_created           (created_at)
) ENGINE=InnoDB;

-- ─────────────────────────────────────────────────────────────────────────────
-- Users  (tie national IDs, connection history, and geo together)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS users (
    id                          BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    national_id                 BIGINT UNSIGNED NULL,
    username                    VARCHAR(128)    NOT NULL,
    last_known_ip               VARCHAR(45)     NULL,
    last_geo_id                 BIGINT UNSIGNED NULL,
    created_at                  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY fk_user_nat     (national_id) REFERENCES national_ids(id) ON DELETE SET NULL,
    FOREIGN KEY fk_user_geo     (last_geo_id) REFERENCES geo_locations(id) ON DELETE SET NULL,
    INDEX idx_username          (username),
    INDEX idx_last_ip           (last_known_ip)
) ENGINE=InnoDB;

-- ─────────────────────────────────────────────────────────────────────────────
-- Status snapshots  (ConnectionStatusServer — uptime, memory, connection count)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS status_snapshots (
    id                          BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    active_connections          INT UNSIGNED    NOT NULL DEFAULT 0,
    server_uptime_secs          BIGINT UNSIGNED NOT NULL DEFAULT 0,
    total_memory_mb             INT UNSIGNED    NOT NULL DEFAULT 0,
    used_memory_mb              INT UNSIGNED    NOT NULL DEFAULT 0,
    local_server_time           DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    snapped_at                  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_snapped           (snapped_at)
) ENGINE=InnoDB;

-- ─────────────────────────────────────────────────────────────────────────────
-- CIA  (reserved for future intelligence-agency integration)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS cia (
    id                          BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id                     BIGINT UNSIGNED NULL,
    national_id                 BIGINT UNSIGNED NULL,
    source_ip                   VARCHAR(45)     NULL,
    geo_id                      BIGINT UNSIGNED NULL,
    classification              VARCHAR(64)     NOT NULL DEFAULT 'UNCLASSIFIED',
    notes                       TEXT            NULL,
    flagged_at                  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY fk_cia_user     (user_id)      REFERENCES users(id)         ON DELETE SET NULL,
    FOREIGN KEY fk_cia_nat      (national_id)  REFERENCES national_ids(id)  ON DELETE SET NULL,
    FOREIGN KEY fk_cia_geo      (geo_id)       REFERENCES geo_locations(id) ON DELETE SET NULL,
    INDEX idx_classification    (classification),
    INDEX idx_flagged           (flagged_at)
) ENGINE=InnoDB;

-- ─────────────────────────────────────────────────────────────────────────────
-- FBI  (reserved for future law-enforcement integration)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS fbi (
    id                          BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id                     BIGINT UNSIGNED NULL,
    national_id                 BIGINT UNSIGNED NULL,
    source_ip                   VARCHAR(45)     NULL,
    geo_id                      BIGINT UNSIGNED NULL,
    case_number                 VARCHAR(64)     NULL,
    classification              VARCHAR(64)     NOT NULL DEFAULT 'UNCLASSIFIED',
    notes                       TEXT            NULL,
    flagged_at                  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY fk_fbi_user     (user_id)      REFERENCES users(id)         ON DELETE SET NULL,
    FOREIGN KEY fk_fbi_nat      (national_id)  REFERENCES national_ids(id)  ON DELETE SET NULL,
    FOREIGN KEY fk_fbi_geo      (geo_id)       REFERENCES geo_locations(id) ON DELETE SET NULL,
    INDEX idx_case              (case_number),
    INDEX idx_classification    (classification),
    INDEX idx_flagged           (flagged_at)
) ENGINE=InnoDB;

SQL

echo "[N21] All tables created successfully."
