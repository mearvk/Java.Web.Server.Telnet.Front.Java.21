-- ============================================================
-- MySQL Schema Update: democratic_d500 — AI Server Tables
-- Installer ID: MEARVK LLC - Max Rupplin
-- D500 Democratic President
-- New tables for AI monitoring, profiling, agreements, disk awareness
-- ============================================================

USE democratic_d500;

-- ── Person Profiles (from 5000-byte initial classification) ───

CREATE TABLE IF NOT EXISTS person_profiles (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    ip_address      VARCHAR(45) NOT NULL,
    profile_text    TEXT,
    hostile         BOOLEAN DEFAULT FALSE,
    unfunny         BOOLEAN DEFAULT FALSE,
    sane            BOOLEAN DEFAULT TRUE,
    liberal         BOOLEAN DEFAULT FALSE,
    entropy_score   FLOAT,
    classification  VARCHAR(64),
    reason          TEXT,
    profiled_ts     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_ip (ip_address),
    INDEX idx_classification (classification)
) ENGINE=InnoDB;

-- ── Agreements (entered after sane/liberal verification) ──────

CREATE TABLE IF NOT EXISTS agreements (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    profile_id      BIGINT NOT NULL,
    ip_address      VARCHAR(45) NOT NULL,
    agreed_ts       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    paragraphs_allowed INT DEFAULT 3800,
    paragraphs_used    INT DEFAULT 0,
    status          ENUM('ACTIVE','COMPLETED','TERMINATED') DEFAULT 'ACTIVE',
    FOREIGN KEY (profile_id) REFERENCES person_profiles(id),
    INDEX idx_ip (ip_address),
    INDEX idx_status (status)
) ENGINE=InnoDB;

-- ── Dismissals (hostile/unfunny → Contact your Local Senator) ─

CREATE TABLE IF NOT EXISTS dismissals (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    profile_id      BIGINT NOT NULL,
    ip_address      VARCHAR(45) NOT NULL,
    reason          TEXT,
    dismissed_ts    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (profile_id) REFERENCES person_profiles(id),
    INDEX idx_ip (ip_address)
) ENGINE=InnoDB;

-- ── AI Training Sessions ──────────────────────────────────────

CREATE TABLE IF NOT EXISTS training_sessions (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    source_file     VARCHAR(512),
    source_type     ENUM('CONFIGURATION','DATA','HEURISTIC') NOT NULL,
    content_hash    VARCHAR(64),
    entries_loaded  INT DEFAULT 0,
    trained_ts      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_type (source_type)
) ENGINE=InnoDB;

-- ── Connection Log (full audit) ──────────────────────────────

CREATE TABLE IF NOT EXISTS connection_log (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    ip_address      VARCHAR(45) NOT NULL,
    port            INT DEFAULT 5000,
    outcome         ENUM('ACCEPTED','REJECTED_CAPACITY','REJECTED_IP','DISMISSED_HOSTILE','DISMISSED_UNFUNNY','DISMISSED_INSANE') NOT NULL,
    connected_ts    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    disconnected_ts TIMESTAMP NULL,
    paragraphs_exchanged INT DEFAULT 0,
    INDEX idx_ip (ip_address),
    INDEX idx_outcome (outcome)
) ENGINE=InnoDB;

-- ── Response Log (CSV/XML output tracking) ───────────────────

CREATE TABLE IF NOT EXISTS response_log (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    agreement_id    BIGINT NOT NULL,
    request_text    TEXT,
    response_format ENUM('CSV','XML','PLAIN') DEFAULT 'PLAIN',
    response_status VARCHAR(32),
    responded_ts    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (agreement_id) REFERENCES agreements(id),
    INDEX idx_agreement (agreement_id)
) ENGINE=InnoDB;

-- ── Server Disk Awareness ─────────────────────────────────────

CREATE TABLE IF NOT EXISTS server_disk_status (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    hostname        VARCHAR(128),
    mount_point     VARCHAR(256),
    total_bytes     BIGINT,
    used_bytes      BIGINT,
    free_bytes      BIGINT,
    percent_used    FLOAT,
    checked_ts      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_mount (mount_point)
) ENGINE=InnoDB;

-- ── Known Servers Registry ────────────────────────────────────

CREATE TABLE IF NOT EXISTS known_servers (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    name            VARCHAR(128),
    repository      VARCHAR(256),
    ip_primary      VARCHAR(45),
    ip_secondary    VARCHAR(45),
    port            INT,
    protocol        VARCHAR(10) DEFAULT 'TCP',
    active          BOOLEAN DEFAULT TRUE,
    registered_ts   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_port (port),
    INDEX idx_active (active)
) ENGINE=InnoDB;
