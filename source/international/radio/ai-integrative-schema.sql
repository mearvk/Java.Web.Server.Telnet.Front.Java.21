-- =============================================================================
-- AI Integrative Database Schema — International Radio Modules
-- =============================================================================
-- MEARVK LLC — NitroWebExpress™
-- Author: Max Rupplin
-- Date: June 19 2026 EST
--
-- Creates the nwe_ai_integrative database with tables for:
--   - Per-country AI knowledge storage
--   - Feedback loop with verdict sourcing
--   - Scouting logs
--   - Training data accumulation
--   - Model scoring and grading
--   - Review of Futures and Conducts
-- =============================================================================

CREATE DATABASE IF NOT EXISTS nwe_ai_integrative
    CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE nwe_ai_integrative;

-- -----------------------------------------------------------------------------
-- Country Knowledge Base (per-module innate + learned knowledge)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS country_knowledge (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    country_id      VARCHAR(32) NOT NULL,
    category        VARCHAR(64) NOT NULL,
    question        TEXT NOT NULL,
    answer          TEXT NOT NULL,
    source          VARCHAR(128) NOT NULL,
    verdict_source  ENUM('HOUSING','LOCAL','INTERNET') NOT NULL DEFAULT 'HOUSING',
    confidence      FLOAT DEFAULT 0.70,
    access_count    INT DEFAULT 0,
    gain_level      ENUM('accept','review','reject') DEFAULT 'accept',
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_country (country_id),
    INDEX idx_category (category),
    INDEX idx_verdict (verdict_source),
    INDEX idx_gain (gain_level)
);

-- -----------------------------------------------------------------------------
-- Feedback Loop — stores verdicts with moral classification
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS feedback_loop (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    country_id      VARCHAR(32) NOT NULL,
    query_text      TEXT NOT NULL,
    response_text   TEXT,
    verdict_source  ENUM('HOUSING','LOCAL','INTERNET') NOT NULL,
    trust_level     FLOAT NOT NULL,
    moral_pass      BOOLEAN DEFAULT TRUE,
    language_score  FLOAT DEFAULT 0.0,
    mortality_score FLOAT DEFAULT 0.0,
    explicit_flag   BOOLEAN DEFAULT FALSE,
    channel         ENUM('public','private') DEFAULT 'public',
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_country (country_id),
    INDEX idx_moral (moral_pass),
    INDEX idx_explicit (explicit_flag)
);

-- -----------------------------------------------------------------------------
-- Scouting Log — daily internet scouting results
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS scouting_log (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    country_id      VARCHAR(32) NOT NULL,
    source_url      VARCHAR(512),
    source_id       VARCHAR(64),
    content         LONGTEXT,
    content_size_bytes BIGINT DEFAULT 0,
    gain_level      ENUM('accept','review','reject') DEFAULT 'review',
    scouted_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    consumed_by_training BOOLEAN DEFAULT FALSE,
    INDEX idx_country (country_id),
    INDEX idx_consumed (consumed_by_training),
    INDEX idx_gain (gain_level)
);

-- -----------------------------------------------------------------------------
-- Training Pairs — accumulated from scouting + received questions
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS training_pairs (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    country_id      VARCHAR(32) NOT NULL,
    input_text      TEXT NOT NULL,
    output_text     TEXT NOT NULL,
    source          VARCHAR(128),
    verdict_source  ENUM('HOUSING','LOCAL','INTERNET') DEFAULT 'INTERNET',
    language_score  FLOAT DEFAULT 0.0,
    mortality_score FLOAT DEFAULT 0.0,
    accepted        BOOLEAN DEFAULT FALSE,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_country (country_id),
    INDEX idx_accepted (accepted)
);

-- -----------------------------------------------------------------------------
-- Model Scoring — grading mechanism for stored models
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS model_scores (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    model_name      VARCHAR(128) NOT NULL,
    country_id      VARCHAR(32),
    language_grade  FLOAT NOT NULL DEFAULT 0.0,
    mortality_grade FLOAT NOT NULL DEFAULT 0.0,
    composite_score FLOAT NOT NULL DEFAULT 0.0,
    sample_count    INT DEFAULT 0,
    model_data      LONGBLOB,
    is_best         BOOLEAN DEFAULT FALSE,
    scored_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_best (is_best),
    INDEX idx_composite (composite_score DESC)
);

-- -----------------------------------------------------------------------------
-- Review of Futures and Conducts — documentable scoring aspect
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS review_futures_conducts (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    country_id      VARCHAR(32) NOT NULL,
    review_period   VARCHAR(32) NOT NULL,
    language_assessment TEXT,
    mortality_assessment TEXT,
    futures_outlook TEXT,
    conduct_notes   TEXT,
    composite_score FLOAT DEFAULT 0.0,
    reviewer        VARCHAR(64) DEFAULT 'AI_TRAINING_THREAD',
    reviewed_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_country (country_id),
    INDEX idx_period (review_period)
);

-- -----------------------------------------------------------------------------
-- Connector Activity — logs NWE module interface interactions
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS connector_activity (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    country_id      VARCHAR(32) NOT NULL,
    connector_id    VARCHAR(64) NOT NULL,
    direction       ENUM('INBOUND','OUTBOUND') NOT NULL,
    query_text      TEXT,
    response_text   TEXT,
    latency_ms      INT DEFAULT 0,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_country (country_id),
    INDEX idx_connector (connector_id)
);
