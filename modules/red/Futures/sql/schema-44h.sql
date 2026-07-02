-- ============================================================
-- MySQL Schema: pledge_44h
-- Secondary Database for 44H Document
-- D44/N44 — University of North Carolina at Chapel Hill
-- Proof of Living Consciousness and One Contract
-- Authenticity guaranteed by Max Rupplin, Senior Honest
-- MEARVK LLC — United States
-- ============================================================

CREATE DATABASE IF NOT EXISTS pledge_44h
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE pledge_44h;

-- ── 44H Document Versions ─────────────────────────────────────

CREATE TABLE document_versions (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    content         TEXT NOT NULL,
    content_hash    VARCHAR(64) NOT NULL,
    byte_length     INT NOT NULL,
    source_url      VARCHAR(512) NOT NULL DEFAULT 'https://raw.githubusercontent.com/mearvk/Senior.Senate.Attorney.E44Hrs/main/44H',
    fetched_ts      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    validated       BOOLEAN DEFAULT TRUE,
    validation_note VARCHAR(256),
    authenticity    VARCHAR(128) DEFAULT 'Guaranteed by Max Rupplin, Senior Honest — MEARVK LLC',
    INDEX idx_hash (content_hash),
    INDEX idx_ts (fetched_ts)
) ENGINE=InnoDB;

-- ── Fetch Attempts (all attempts logged for security) ─────────

CREATE TABLE fetch_attempts (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    attempted_ts    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    http_code       INT,
    content_hash    VARCHAR(64),
    byte_length     INT,
    safe            BOOLEAN,
    rejection_reason VARCHAR(256),
    stored          BOOLEAN DEFAULT FALSE,
    INDEX idx_ts (attempted_ts),
    INDEX idx_safe (safe)
) ENGINE=InnoDB;
