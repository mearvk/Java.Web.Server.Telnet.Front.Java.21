-- integrity/integrity-schema.sql
-- SHA-256/MD5 File Integrity Database
-- Gifted Install Tech ID
-- Security principles: immutable audit log, no deletes, timestamped

CREATE DATABASE IF NOT EXISTS nwe_integrity
    CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE nwe_integrity;

-- File digest records (append-only)
CREATE TABLE IF NOT EXISTS file_digests (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    file_path       VARCHAR(512) NOT NULL,
    sha256          CHAR(64) NOT NULL,
    md5             CHAR(32) NOT NULL,
    size_bytes      BIGINT NOT NULL,
    mtime_epoch     BIGINT NOT NULL,
    scan_timestamp  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    commit_sha      CHAR(40),
    trusted_repo    VARCHAR(255),
    match_status    ENUM('MATCH', 'MISMATCH', 'UNVERIFIED') NOT NULL DEFAULT 'UNVERIFIED',
    INDEX idx_file_path (file_path),
    INDEX idx_scan_ts (scan_timestamp),
    INDEX idx_status (match_status)
) ENGINE=InnoDB;

-- Concerns log (immutable — no UPDATE/DELETE granted)
CREATE TABLE IF NOT EXISTS integrity_concerns (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    concern_time    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    file_path       VARCHAR(512) NOT NULL,
    local_sha256    CHAR(64),
    remote_sha      CHAR(40),
    commit_sha      CHAR(40),
    trusted_repo    VARCHAR(255),
    severity        ENUM('INFO', 'WARN', 'CRITICAL') NOT NULL DEFAULT 'WARN',
    resolved        BOOLEAN NOT NULL DEFAULT FALSE,
    INDEX idx_concern_time (concern_time),
    INDEX idx_severity (severity)
) ENGINE=InnoDB;

-- Scan history
CREATE TABLE IF NOT EXISTS scan_history (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    scan_timestamp  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    total_files     INT NOT NULL,
    concerns_found  INT NOT NULL DEFAULT 0,
    commit_sha      CHAR(40),
    tech_id         VARCHAR(100) NOT NULL DEFAULT 'Gifted Install Tech ID'
) ENGINE=InnoDB;

-- Security: read-only user for application, no DELETE/UPDATE on concerns
CREATE USER IF NOT EXISTS 'nwe_integrity_ro'@'localhost' IDENTIFIED BY 'integrity_read_only_2026';
GRANT SELECT ON nwe_integrity.* TO 'nwe_integrity_ro'@'localhost';

CREATE USER IF NOT EXISTS 'nwe_integrity_rw'@'localhost' IDENTIFIED BY 'integrity_write_2026';
GRANT SELECT, INSERT ON nwe_integrity.* TO 'nwe_integrity_rw'@'localhost';
-- No UPDATE or DELETE on integrity_concerns — immutable audit
GRANT UPDATE ON nwe_integrity.file_digests TO 'nwe_integrity_rw'@'localhost';

FLUSH PRIVILEGES;
