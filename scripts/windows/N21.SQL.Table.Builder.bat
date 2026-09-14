@echo off
REM N21.SQL.Table.Builder.bat — create database N21 and all application tables (Windows)

echo [N21] Creating database N21...

mysql -u root -p -e ^"^
CREATE DATABASE IF NOT EXISTS N21 CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;^
USE N21;^
^
CREATE TABLE IF NOT EXISTS connections (^
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,^
    remote_address VARCHAR(255) NOT NULL,^
    internet_address VARCHAR(45) NOT NULL,^
    server_port SMALLINT UNSIGNED NOT NULL,^
    is_telnet_excelsior_connected TINYINT(1) NOT NULL DEFAULT 0,^
    inception_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,^
    closed_date DATETIME NULL,^
    INDEX idx_remote (remote_address),^
    INDEX idx_inception (inception_date)^
) ENGINE=InnoDB;^
^
CREATE TABLE IF NOT EXISTS geo_locations (^
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,^
    ip_address VARCHAR(45) NOT NULL,^
    city VARCHAR(128) NOT NULL DEFAULT '',^
    country VARCHAR(128) NOT NULL DEFAULT '',^
    resolved_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,^
    UNIQUE KEY uq_ip (ip_address),^
    INDEX idx_country (country)^
) ENGINE=InnoDB;^
^
CREATE TABLE IF NOT EXISTS exceptions (^
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,^
    exception_type VARCHAR(255) NOT NULL,^
    message TEXT NULL,^
    origin VARCHAR(1024) NOT NULL,^
    stack_trace MEDIUMTEXT NOT NULL,^
    is_security_event TINYINT(1) NOT NULL DEFAULT 0,^
    recorded_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,^
    INDEX idx_type (exception_type),^
    INDEX idx_security (is_security_event),^
    INDEX idx_recorded (recorded_at)^
) ENGINE=InnoDB;^
^
CREATE TABLE IF NOT EXISTS security_events (^
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,^
    exception_id BIGINT UNSIGNED NULL,^
    event_type VARCHAR(128) NOT NULL,^
    message TEXT NULL,^
    origin VARCHAR(1024) NOT NULL,^
    source_ip VARCHAR(45) NULL,^
    alert_triggered TINYINT(1) NOT NULL DEFAULT 0,^
    recorded_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,^
    FOREIGN KEY fk_sec_exc (exception_id) REFERENCES exceptions(id) ON DELETE SET NULL,^
    INDEX idx_event_type (event_type),^
    INDEX idx_source_ip (source_ip),^
    INDEX idx_recorded (recorded_at)^
) ENGINE=InnoDB;^
^
CREATE TABLE IF NOT EXISTS national_ids (^
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,^
    eight_digit_id BIGINT UNSIGNED NOT NULL,^
    sixteen_digit_key BIGINT UNSIGNED NOT NULL,^
    issued_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,^
    UNIQUE KEY uq_eight (eight_digit_id)^
) ENGINE=InnoDB;^
^
CREATE TABLE IF NOT EXISTS national_finance_ids (^
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,^
    national_id BIGINT UNSIGNED NOT NULL,^
    remote_address VARCHAR(45) NOT NULL DEFAULT '',^
    iq SMALLINT UNSIGNED NOT NULL DEFAULT 0,^
    education_level VARCHAR(128) NOT NULL DEFAULT '',^
    social_skills TINYINT UNSIGNED NOT NULL DEFAULT 0,^
    equipment TEXT NULL,^
    trust_level TINYINT UNSIGNED NOT NULL DEFAULT 0,^
    parent_one VARCHAR(255) NOT NULL DEFAULT '',^
    parent_two VARCHAR(255) NOT NULL DEFAULT '',^
    suspects TEXT NULL,^
    social_spotting TEXT NULL,^
    promissory_note DECIMAL(18,2) NOT NULL DEFAULT 0.00,^
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,^
    FOREIGN KEY fk_nfid_nat (national_id) REFERENCES national_ids(eight_digit_id) ON DELETE CASCADE,^
    INDEX idx_nfid_national_id (national_id),^
    INDEX idx_nfid_trust (trust_level),^
    INDEX idx_nfid_created (created_at)^
) ENGINE=InnoDB;^
^
CREATE TABLE IF NOT EXISTS users (^
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,^
    national_id BIGINT UNSIGNED NULL,^
    username VARCHAR(128) NOT NULL,^
    last_known_ip VARCHAR(45) NULL,^
    last_geo_id BIGINT UNSIGNED NULL,^
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,^
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,^
    FOREIGN KEY fk_user_nat (national_id) REFERENCES national_ids(id) ON DELETE SET NULL,^
    FOREIGN KEY fk_user_geo (last_geo_id) REFERENCES geo_locations(id) ON DELETE SET NULL,^
    INDEX idx_username (username),^
    INDEX idx_last_ip (last_known_ip)^
) ENGINE=InnoDB;^
^
CREATE TABLE IF NOT EXISTS status_snapshots (^
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,^
    active_connections INT UNSIGNED NOT NULL DEFAULT 0,^
    server_uptime_secs BIGINT UNSIGNED NOT NULL DEFAULT 0,^
    total_memory_mb INT UNSIGNED NOT NULL DEFAULT 0,^
    used_memory_mb INT UNSIGNED NOT NULL DEFAULT 0,^
    local_server_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,^
    snapped_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,^
    INDEX idx_snapped (snapped_at)^
) ENGINE=InnoDB;^
^
CREATE TABLE IF NOT EXISTS cia (^
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,^
    user_id BIGINT UNSIGNED NULL,^
    national_id BIGINT UNSIGNED NULL,^
    source_ip VARCHAR(45) NULL,^
    geo_id BIGINT UNSIGNED NULL,^
    classification VARCHAR(64) NOT NULL DEFAULT 'UNCLASSIFIED',^
    notes TEXT NULL,^
    flagged_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,^
    FOREIGN KEY fk_cia_user (user_id) REFERENCES users(id) ON DELETE SET NULL,^
    FOREIGN KEY fk_cia_nat (national_id) REFERENCES national_ids(id) ON DELETE SET NULL,^
    FOREIGN KEY fk_cia_geo (geo_id) REFERENCES geo_locations(id) ON DELETE SET NULL,^
    INDEX idx_classification (classification),^
    INDEX idx_flagged (flagged_at)^
) ENGINE=InnoDB;^
^
CREATE TABLE IF NOT EXISTS fbi (^
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,^
    user_id BIGINT UNSIGNED NULL,^
    national_id BIGINT UNSIGNED NULL,^
    source_ip VARCHAR(45) NULL,^
    geo_id BIGINT UNSIGNED NULL,^
    case_number VARCHAR(64) NULL,^
    classification VARCHAR(64) NOT NULL DEFAULT 'UNCLASSIFIED',^
    notes TEXT NULL,^
    flagged_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,^
    FOREIGN KEY fk_fbi_user (user_id) REFERENCES users(id) ON DELETE SET NULL,^
    FOREIGN KEY fk_fbi_nat (national_id) REFERENCES national_ids(id) ON DELETE SET NULL,^
    FOREIGN KEY fk_fbi_geo (geo_id) REFERENCES geo_locations(id) ON DELETE SET NULL,^
    INDEX idx_case (case_number),^
    INDEX idx_classification (classification),^
    INDEX idx_flagged (flagged_at)^
) ENGINE=InnoDB;^
^
SET GLOBAL max_allowed_packet = 10485760;^
^
CREATE TABLE IF NOT EXISTS bitcoin_transactions (^
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,^
    national_id BIGINT UNSIGNED NOT NULL,^
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),^
    updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),^
    source_ip VARCHAR(45) NOT NULL DEFAULT '',^
    dest_ip VARCHAR(45) NOT NULL DEFAULT '',^
    wallet_signature VARCHAR(8192) NOT NULL DEFAULT '',^
    imagograph LONGBLOB NULL,^
    final_signatory VARCHAR(512) NOT NULL DEFAULT '',^
    aes_key_source CHAR(64) NOT NULL DEFAULT '',^
    aes_key_dest CHAR(64) NOT NULL DEFAULT '',^
    aes_key_owner CHAR(64) NOT NULL DEFAULT '',^
    FOREIGN KEY fk_btc_nat (national_id) REFERENCES national_ids(eight_digit_id) ON DELETE CASCADE,^
    INDEX idx_btc_national_id (national_id),^
    INDEX idx_btc_source_ip (source_ip),^
    INDEX idx_btc_dest_ip (dest_ip),^
    INDEX idx_btc_created (created_at),^
    INDEX idx_btc_signatory (final_signatory(64))^
) ENGINE=InnoDB ROW_FORMAT=DYNAMIC;^
^
CREATE TABLE IF NOT EXISTS ascii_signatures (^
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,^
    national_id BIGINT UNSIGNED NOT NULL,^
    sig_id INT UNSIGNED NOT NULL,^
    ascii_grid TEXT NOT NULL,^
    issued_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,^
    expires_at DATETIME NOT NULL,^
    UNIQUE KEY uq_national (national_id),^
    UNIQUE KEY uq_sig_id (sig_id),^
    INDEX idx_expires (expires_at)^
) ENGINE=InnoDB;^
^
CREATE TABLE IF NOT EXISTS module_loader (^
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,^
    national_id BIGINT UNSIGNED NOT NULL,^
    module_name VARCHAR(255) NOT NULL,^
    action VARCHAR(64) NOT NULL,^
    source_ip VARCHAR(45) NOT NULL DEFAULT '',^
    file_type VARCHAR(16) NOT NULL DEFAULT '',^
    byte_count INT UNSIGNED NOT NULL DEFAULT 0,^
    sig_hex VARCHAR(64) NOT NULL DEFAULT '',^
    admin_token VARCHAR(128) NOT NULL DEFAULT '',^
    result VARCHAR(255) NOT NULL DEFAULT '',^
    recorded_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,^
    INDEX idx_ml_national (national_id),^
    INDEX idx_ml_module (module_name),^
    INDEX idx_ml_action (action),^
    INDEX idx_ml_recorded (recorded_at)^
) ENGINE=InnoDB;^
"

if %ERRORLEVEL% EQU 0 (
    echo [N21] All tables created successfully.
) else (
    echo [N21] ERROR: Table creation failed.
    exit /b 1
)
