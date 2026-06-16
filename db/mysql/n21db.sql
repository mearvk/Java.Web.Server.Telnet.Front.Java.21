-- N21 Database Schema
-- Generated 2026-06-16

CREATE DATABASE IF NOT EXISTS N21
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE N21;

-- ── connections ──────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS connections (
  id                           BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  remote_address               VARCHAR(255) NOT NULL DEFAULT '',
  internet_address             VARCHAR(45)  NOT NULL DEFAULT '',
  server_port                  INT          NOT NULL,
  is_telnet_excelsior_connected TINYINT(1)  NOT NULL DEFAULT 0,
  inception_date               DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ── geo_locations ────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS geo_locations (
  ip_address  VARCHAR(45)  NOT NULL PRIMARY KEY,
  CITY        VARCHAR(255) NOT NULL DEFAULT '',
  COUNTRY     VARCHAR(255) NOT NULL DEFAULT '',
  resolved_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ── exceptions ───────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS exceptions (
  id               BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  exception_type   VARCHAR(255) NOT NULL DEFAULT '',
  message          TEXT,
  origin           VARCHAR(255) NOT NULL DEFAULT '',
  stack_trace      TEXT,
  is_security_event TINYINT(1)  NOT NULL DEFAULT 0,
  recorded_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ── security_events ──────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS security_events (
  id          BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  event_type  VARCHAR(255) NOT NULL DEFAULT '',
  message     TEXT,
  origin      VARCHAR(255) NOT NULL DEFAULT '',
  source_ip   VARCHAR(45)  NOT NULL DEFAULT '',
  recorded_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ── national_ids ─────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS national_ids (
  id               BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  eight_digit_id   BIGINT UNSIGNED NOT NULL,
  sixteen_digit_key BIGINT UNSIGNED NOT NULL,
  UNIQUE KEY uq_eight_digit (eight_digit_id)
) ENGINE=InnoDB;

-- ── national_finance_ids ─────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS national_finance_ids (
  id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  national_id     BIGINT UNSIGNED NOT NULL,
  remote_address  VARCHAR(255) NOT NULL DEFAULT '',
  iq              INT          NOT NULL DEFAULT 0,
  education_level VARCHAR(255) NOT NULL DEFAULT '',
  social_skills   INT          NOT NULL DEFAULT 0,
  equipment       VARCHAR(255) NOT NULL DEFAULT '',
  trust_level     INT          NOT NULL DEFAULT 0,
  parent_one      VARCHAR(255) NOT NULL DEFAULT '',
  parent_two      VARCHAR(255) NOT NULL DEFAULT '',
  suspects        TEXT,
  social_spotting TEXT,
  promissory_note DOUBLE       NOT NULL DEFAULT 0.0,
  created_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_nfi_national (national_id),
  CONSTRAINT fk_nfi_national FOREIGN KEY (national_id) REFERENCES national_ids(eight_digit_id)
) ENGINE=InnoDB;

-- ── user_keypairs ────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS user_keypairs (
  id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  national_id     BIGINT UNSIGNED NOT NULL,
  rsa_public_key  TEXT NOT NULL,
  rsa_private_key TEXT NOT NULL,
  dsa_public_key  TEXT NOT NULL,
  dsa_private_key TEXT NOT NULL,
  aes_key         TEXT NOT NULL,
  created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_national_id (national_id)
) ENGINE=InnoDB;

-- ── ascii_signatures ─────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS ascii_signatures (
  id          BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  national_id BIGINT UNSIGNED NOT NULL,
  sig_id      INT UNSIGNED    NOT NULL,
  ascii_grid  TEXT            NOT NULL,
  issued_at   DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  expires_at  DATETIME        NOT NULL,
  UNIQUE KEY uq_national (national_id),
  UNIQUE KEY uq_sig_id   (sig_id),
  INDEX idx_expires      (expires_at)
) ENGINE=InnoDB;

-- ── module_loader ────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS module_loader (
  id            BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  national_id   BIGINT UNSIGNED NOT NULL,
  module_name   VARCHAR(255)    NOT NULL,
  action        VARCHAR(64)     NOT NULL,
  source_ip     VARCHAR(45)     NOT NULL DEFAULT '',
  file_type     VARCHAR(16)     NOT NULL DEFAULT '',
  byte_count    INT UNSIGNED    NOT NULL DEFAULT 0,
  sig_hex       VARCHAR(64)     NOT NULL DEFAULT '',
  admin_token   VARCHAR(128)    NOT NULL DEFAULT '',
  result        VARCHAR(255)    NOT NULL DEFAULT '',
  recorded_at   DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_ml_national  (national_id),
  INDEX idx_ml_module    (module_name),
  INDEX idx_ml_action    (action),
  INDEX idx_ml_recorded  (recorded_at)
) ENGINE=InnoDB;

-- ── communicator_messages ────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS communicator_messages (
  id               BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  from_national_id BIGINT          NOT NULL,
  to_national_id   BIGINT          NOT NULL,
  message          TEXT            NOT NULL,
  type             VARCHAR(16)     NOT NULL DEFAULT 'direct',
  sent_at          DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_cm_from    (from_national_id),
  INDEX idx_cm_to      (to_national_id),
  INDEX idx_cm_sent    (sent_at)
) ENGINE=InnoDB;

-- ── communicator_scheduled ───────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS communicator_scheduled (
  id               BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  from_national_id BIGINT          NOT NULL,
  to_national_id   BIGINT          NOT NULL,
  message          TEXT            NOT NULL,
  scheduled_time   VARCHAR(5)      NOT NULL,
  delivered        TINYINT(1)      NOT NULL DEFAULT 0,
  created_at       DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  delivered_at     DATETIME,
  INDEX idx_cs_pending (delivered, scheduled_time)
) ENGINE=InnoDB;

-- ── bitcoin_trades ───────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS bitcoin_trades (
  id          BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  action      VARCHAR(64)  NOT NULL,
  wallet      VARCHAR(255) NOT NULL DEFAULT '',
  detail      TEXT         NOT NULL,
  result      TEXT         NOT NULL,
  recorded_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_bt_action   (action),
  INDEX idx_bt_recorded (recorded_at)
) ENGINE=InnoDB;

-- ── status_snapshots ─────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS status_snapshots (
  id                 BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  active_connections INT          NOT NULL DEFAULT 0,
  server_uptime_secs BIGINT      NOT NULL DEFAULT 0,
  total_memory_mb    BIGINT      NOT NULL DEFAULT 0,
  used_memory_mb     BIGINT      NOT NULL DEFAULT 0,
  local_server_time  DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ── user_proxy_selections ────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS user_proxy_selections (
  id          BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  national_id BIGINT UNSIGNED NOT NULL,
  proxy_host  VARCHAR(255)    NOT NULL,
  proxy_port  INT UNSIGNED    NOT NULL,
  active      TINYINT(1)      NOT NULL DEFAULT 1,
  created_at  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_national_proxy (national_id)
) ENGINE=InnoDB;

-- ── session_routing_log ──────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS session_routing_log (
  id          BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  national_id BIGINT UNSIGNED NOT NULL,
  action      VARCHAR(64)     NOT NULL,
  proxy_host  VARCHAR(255)    NOT NULL DEFAULT '',
  proxy_port  INT UNSIGNED    NOT NULL DEFAULT 0,
  recorded_at DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_srl_national (national_id),
  INDEX idx_srl_action   (action)
) ENGINE=InnoDB;

-- ── wat_tasks (White Auditor) ────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS wat_tasks (
  id               BIGINT AUTO_INCREMENT PRIMARY KEY,
  from_national_id BIGINT       NOT NULL,
  to_national_id   BIGINT       NOT NULL,
  type             VARCHAR(32)  NOT NULL,
  filename         VARCHAR(255),
  size             INT,
  payload          LONGTEXT,
  created_at       TIMESTAMP    DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;
