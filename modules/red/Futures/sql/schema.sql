-- ============================================================
-- MySQL Schema: democratic_d500
-- Installer ID: MEARVK LLC - Max Rupplin
-- D500 Democratic President
-- INT Tax Defense & Democratic Services
-- ============================================================

CREATE DATABASE IF NOT EXISTS democratic_d500
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE democratic_d500;

-- ── Registrations ─────────────────────────────────────────────

CREATE TABLE registrations (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    citizen_id      VARCHAR(64) NOT NULL,
    full_name       VARCHAR(255) NOT NULL,
    jurisdiction    VARCHAR(64),
    registration_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address      VARCHAR(45),
    status          ENUM('ACTIVE','SUSPENDED','REVOKED') DEFAULT 'ACTIVE',
    INDEX idx_citizen (citizen_id),
    INDEX idx_status (status)
) ENGINE=InnoDB;

-- ── Deregistrations ───────────────────────────────────────────

CREATE TABLE deregistrations (
    id                  BIGINT AUTO_INCREMENT PRIMARY KEY,
    registration_id     BIGINT NOT NULL,
    citizen_id          VARCHAR(64) NOT NULL,
    reason              TEXT,
    deregistration_ts   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address          VARCHAR(45),
    FOREIGN KEY (registration_id) REFERENCES registrations(id),
    INDEX idx_citizen (citizen_id)
) ENGINE=InnoDB;

-- ── Questions ─────────────────────────────────────────────────

CREATE TABLE questions (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    citizen_id      VARCHAR(64) NOT NULL,
    question_text   TEXT NOT NULL,
    category        VARCHAR(64),
    submitted_ts    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status          ENUM('PENDING','ANSWERED','CLOSED') DEFAULT 'PENDING',
    INDEX idx_citizen (citizen_id),
    INDEX idx_status (status)
) ENGINE=InnoDB;

-- ── Answers ───────────────────────────────────────────────────

CREATE TABLE answers (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    question_id     BIGINT NOT NULL,
    answer_text     TEXT NOT NULL,
    answered_by     VARCHAR(128),
    answered_ts     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (question_id) REFERENCES questions(id),
    INDEX idx_question (question_id)
) ENGINE=InnoDB;

-- ── Speculation Requests ──────────────────────────────────────

CREATE TABLE speculation_requests (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    citizen_id      VARCHAR(64) NOT NULL,
    input_features  JSON NOT NULL,
    requested_ts    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status          ENUM('QUEUED','PROCESSING','COMPLETE','FAILED') DEFAULT 'QUEUED',
    INDEX idx_citizen (citizen_id),
    INDEX idx_status (status)
) ENGINE=InnoDB;

-- ── Speculation Results ───────────────────────────────────────

CREATE TABLE speculation_results (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    request_id      BIGINT NOT NULL,
    closure_prob    FLOAT,
    defense_strength FLOAT,
    settlement_range FLOAT,
    appeal_viability FLOAT,
    computed_ts     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (request_id) REFERENCES speculation_requests(id),
    INDEX idx_request (request_id)
) ENGINE=InnoDB;

-- ── Tax Closures ──────────────────────────────────────────────

CREATE TABLE tax_closures (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    case_number     VARCHAR(64) NOT NULL UNIQUE,
    citizen_id      VARCHAR(64) NOT NULL,
    jurisdiction    VARCHAR(64),
    closure_type    ENUM('VOLUNTARY','INVOLUNTARY','SETTLEMENT','APPEAL') NOT NULL,
    amount_owed     DECIMAL(15,2),
    amount_settled  DECIMAL(15,2),
    opened_ts       TIMESTAMP,
    closed_ts       TIMESTAMP,
    status          ENUM('OPEN','CLOSED','APPEALED') DEFAULT 'OPEN',
    INDEX idx_citizen (citizen_id),
    INDEX idx_case (case_number),
    INDEX idx_status (status)
) ENGINE=InnoDB;

-- ── Defense Cases ─────────────────────────────────────────────

CREATE TABLE defense_cases (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    closure_id      BIGINT NOT NULL,
    strategy_id     INT,
    confidence      FLOAT,
    expected_outcome VARCHAR(128),
    resolution_days INT,
    created_ts      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (closure_id) REFERENCES tax_closures(id),
    INDEX idx_closure (closure_id)
) ENGINE=InnoDB;
