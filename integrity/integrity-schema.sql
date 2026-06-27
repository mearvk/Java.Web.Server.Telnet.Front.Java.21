-- integrity/integrity-schema.sql
-- SHA-256 File Integrity Database
-- Gifted Install Tech ID
--
-- Security: read-only digest table locked by honor_oath table.
-- Originals preserved on update. Self-integrity stored in DB.

CREATE DATABASE IF NOT EXISTS nwe_integrity
    CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE nwe_integrity;

-- Honor oath — locks the integrity tables. Must be intact for digests to be trusted.
-- Swears honor to process and country.
CREATE TABLE IF NOT EXISTS honor_oath (
    id              INT PRIMARY KEY DEFAULT 1,
    oath            TEXT NOT NULL DEFAULT 'I swear honor to process and country. This integrity system serves truth, transparency, and the preservation of trusted software.',
    oath_sha256     CHAR(64) NOT NULL,
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    sworn_by        VARCHAR(100) NOT NULL DEFAULT 'Gifted Install Tech ID',
    country         VARCHAR(50) NOT NULL DEFAULT 'United States of America',
    CONSTRAINT single_oath CHECK (id = 1)
) ENGINE=InnoDB;

-- Insert the oath (SHA-256 of the oath text itself)
INSERT IGNORE INTO honor_oath (id, oath, oath_sha256, sworn_by) VALUES (
    1,
    'I swear honor to process and country. This integrity system serves truth, transparency, and the preservation of trusted software.',
    SHA2('I swear honor to process and country. This integrity system serves truth, transparency, and the preservation of trusted software.', 256),
    'Gifted Install Tech ID'
);

-- File digests — the main integrity table (read-only by application)
-- Updates allowed but originals preserved in file_digests_history
CREATE TABLE IF NOT EXISTS file_digests (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    file_path       VARCHAR(512) NOT NULL,
    sha256          CHAR(64) NOT NULL,
    md5             CHAR(32) NOT NULL,
    size_bytes      BIGINT NOT NULL,
    commit_sha      CHAR(40) NOT NULL,
    trusted_repo    VARCHAR(255) NOT NULL,
    branch          VARCHAR(100) NOT NULL DEFAULT 'main',
    scan_timestamp  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    match_status    ENUM('MATCH', 'MISMATCH', 'RESTORED', 'UPDATED') NOT NULL DEFAULT 'MATCH',
    UNIQUE KEY uk_file_commit (file_path, commit_sha),
    INDEX idx_status (match_status)
) ENGINE=InnoDB;

-- History — originals preserved here on update (append-only, no delete)
CREATE TABLE IF NOT EXISTS file_digests_history (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    original_id     BIGINT NOT NULL,
    file_path       VARCHAR(512) NOT NULL,
    sha256          CHAR(64) NOT NULL,
    md5             CHAR(32) NOT NULL,
    commit_sha      CHAR(40) NOT NULL,
    archived_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    reason          ENUM('UPDATE', 'RESTORE', 'SUPERSEDED') NOT NULL,
    INDEX idx_file (file_path),
    INDEX idx_archived (archived_at)
) ENGINE=InnoDB;

-- Self-integrity: SHA-256 of the integrity scripts themselves
CREATE TABLE IF NOT EXISTS self_integrity (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    script_path     VARCHAR(512) NOT NULL,
    sha256          CHAR(64) NOT NULL,
    commit_sha      CHAR(40) NOT NULL,
    recorded_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_script (script_path)
) ENGINE=InnoDB;

-- Concerns log (append-only)
CREATE TABLE IF NOT EXISTS integrity_concerns (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    concern_time    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    file_path       VARCHAR(512) NOT NULL,
    expected_sha256 CHAR(64),
    actual_sha256   CHAR(64),
    commit_sha      CHAR(40),
    action_taken    ENUM('LOGGED', 'RESTORED', 'FAILED_RESTORE') NOT NULL DEFAULT 'LOGGED',
    INDEX idx_time (concern_time)
) ENGINE=InnoDB;

-- Scan history
CREATE TABLE IF NOT EXISTS scan_history (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    scan_timestamp  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    total_files     INT NOT NULL,
    concerns_found  INT NOT NULL DEFAULT 0,
    restorations    INT NOT NULL DEFAULT 0,
    commit_sha      CHAR(40),
    tech_id         VARCHAR(100) NOT NULL DEFAULT 'Gifted Install Tech ID'
) ENGINE=InnoDB;

-- Security users: app gets SELECT + INSERT only. No DELETE anywhere.
CREATE USER IF NOT EXISTS 'nwe_integrity_ro'@'localhost' IDENTIFIED BY 'integrity_read_only_2026';
GRANT SELECT ON nwe_integrity.* TO 'nwe_integrity_ro'@'localhost';

CREATE USER IF NOT EXISTS 'nwe_integrity_rw'@'localhost' IDENTIFIED BY 'integrity_write_2026';
GRANT SELECT, INSERT ON nwe_integrity.* TO 'nwe_integrity_rw'@'localhost';
GRANT UPDATE (match_status, scan_timestamp) ON nwe_integrity.file_digests TO 'nwe_integrity_rw'@'localhost';
-- No DELETE on any table. No UPDATE on history or concerns.

FLUSH PRIVILEGES;
