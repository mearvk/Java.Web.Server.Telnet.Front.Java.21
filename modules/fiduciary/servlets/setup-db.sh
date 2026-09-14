#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════════
# FiduciaryServices™ — Database Setup
#
# INSTALLER AUTHORITY:
#   Minimum Grade: Level 3 (Local Tech) — can execute this script
#   Design Grade:  Level 9 (Installer Tech) — authored schema and ACH architecture
#   TechID:        mearvk - Installer Tech 2 (Max Rupplin)
#
# Creates nwe_fiduciary database and all tables for:
#   - Knowledge base (fiduciary Q&A)
#   - Architectures (trust, SWF, pension, foundation, escrow)
#   - Records (known fiduciary entities)
#   - Yield models (polyblend components)
#   - ACH transfers and platform registry
#   - Legal bright (INT/IQ Calendar)
#   - Treasure fiduciary (law structures)
#   - AI findings order
#   - Garden news doctrine
#   - AI disposition
#   - Original documents
# SAFE: Uses CREATE IF NOT EXISTS. Never drops or overwrites existing data.
# Installer Tech ID: Max Rupplin
# ═══════════════════════════════════════════════════════════════════════════════════
set -e

echo "[*] Creating nwe_fiduciary database..."

mysql -u root -e "
CREATE DATABASE IF NOT EXISTS nwe_fiduciary CHARACTER SET utf8mb4;
USE nwe_fiduciary;

-- Knowledge base
CREATE TABLE IF NOT EXISTS knowledge_base (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    question VARCHAR(512),
    answer TEXT,
    category VARCHAR(64),
    confidence INT DEFAULT 85,
    access_count INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Architectures
CREATE TABLE IF NOT EXISTS architectures (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(128),
    description TEXT,
    structure_type VARCHAR(64),
    yield_profile VARCHAR(64),
    turn_period VARCHAR(64),
    jurisdiction VARCHAR(128),
    risk_grade VARCHAR(16),
    advantage_class VARCHAR(64)
) ENGINE=InnoDB;

-- Records
CREATE TABLE IF NOT EXISTS records (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    entity_name VARCHAR(256),
    entity_type VARCHAR(64),
    jurisdiction VARCHAR(128),
    fiduciary_type VARCHAR(64),
    assets_under_management VARCHAR(64),
    established_year INT,
    notes TEXT
) ENGINE=InnoDB;

-- Yield models
CREATE TABLE IF NOT EXISTS yield_models (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    model_name VARCHAR(128),
    description TEXT,
    base_yield DECIMAL(8,4),
    turn_frequency VARCHAR(32),
    risk_factor DECIMAL(5,3),
    polyblend_weight DECIMAL(5,3) DEFAULT 1.000,
    assumption_basis VARCHAR(256)
) ENGINE=InnoDB;

-- Sessions
CREATE TABLE IF NOT EXISTS sessions (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    question TEXT,
    answer TEXT,
    session_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Original documents
CREATE TABLE IF NOT EXISTS original_documents (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(512) NOT NULL,
    category VARCHAR(64) NOT NULL,
    subcategory VARCHAR(64),
    jurisdiction VARCHAR(128),
    label VARCHAR(64) DEFAULT 'DOMESTIC',
    document_text TEXT NOT NULL,
    source_url VARCHAR(512),
    source_authority VARCHAR(256),
    retrieval_date DATE DEFAULT (CURRENT_DATE),
    confidence INT DEFAULT 85,
    relevance_to_minister TINYINT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_category (category),
    INDEX idx_label (label),
    INDEX idx_jurisdiction (jurisdiction)
) ENGINE=InnoDB;

-- Legal Bright (INT/IQ Calendar)
CREATE TABLE IF NOT EXISTS legal_bright (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    calendar_half ENUM('TOP','BOTTOM') NOT NULL,
    entry_name VARCHAR(256) NOT NULL,
    concern_type VARCHAR(64) NOT NULL,
    description TEXT NOT NULL,
    ideals TEXT,
    totals TEXT,
    benefit_to VARCHAR(128),
    approach_authority VARCHAR(128),
    nuisance_resolution VARCHAR(256),
    council_note TEXT,
    confidence INT DEFAULT 85,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_half (calendar_half),
    INDEX idx_concern (concern_type)
) ENGINE=InnoDB;

-- Treasure fiduciary
CREATE TABLE IF NOT EXISTS treasure_fiduciary (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    law_structure VARCHAR(256) NOT NULL,
    evidence_basis TEXT NOT NULL,
    approach_type ENUM('DIRECT','COUNCIL','TRY','RESOLUTION') NOT NULL,
    treasure_class VARCHAR(64),
    fiduciary_standing VARCHAR(128),
    nuisance_type VARCHAR(64),
    nuisance_resolution TEXT,
    profitable_idea TEXT,
    try_nuisance TEXT,
    council_resolution TEXT,
    jurisdiction VARCHAR(128),
    confidence INT DEFAULT 85,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_approach (approach_type),
    INDEX idx_treasure_class (treasure_class)
) ENGINE=InnoDB;

-- AI findings order
CREATE TABLE IF NOT EXISTS ai_findings_order (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    ordinal INT NOT NULL,
    finding_level VARCHAR(128) NOT NULL,
    description TEXT NOT NULL,
    scope VARCHAR(64) NOT NULL,
    openness ENUM('OPEN','CLOSED','CAREFUL','SOLD') NOT NULL,
    relation_to_person ENUM('CLOSED','OPEN_CONDUCT','NOT_UNTO_PERSON','ANNALS_FOREVER') NOT NULL,
    evidentiary_weight INT DEFAULT 85,
    garden_news_applicable TINYINT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_ordinal (ordinal)
) ENGINE=InnoDB;

-- Garden news doctrine
CREATE TABLE IF NOT EXISTS garden_news_doctrine (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    principle_name VARCHAR(256) NOT NULL,
    doctrine_text TEXT NOT NULL,
    person_status ENUM('CLOSED','PROTECTED','CAREFUL') NOT NULL DEFAULT 'CLOSED',
    evidence_status ENUM('OPEN','SOLD','ANNALS','FOREVER') NOT NULL DEFAULT 'OPEN',
    conduct_type VARCHAR(64),
    relation_to_truth TINYINT DEFAULT 1,
    relation_to_life TINYINT DEFAULT 1,
    relation_to_history TINYINT DEFAULT 1,
    confidence INT DEFAULT 90,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- AI disposition
CREATE TABLE IF NOT EXISTS ai_disposition (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    attribute_name VARCHAR(128) NOT NULL,
    attribute_value TEXT NOT NULL,
    category VARCHAR(64) NOT NULL,
    confidence INT DEFAULT 90,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_category (category)
) ENGINE=InnoDB;

-- ACH Platforms
CREATE TABLE IF NOT EXISTS ach_platforms (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(32) NOT NULL UNIQUE,
    display_name VARCHAR(64),
    api_base_url VARCHAR(256),
    monthly_fee DECIMAL(10,2) DEFAULT 0.00,
    ach_pct DECIMAL(5,3) DEFAULT 0.000,
    ach_flat DECIMAL(5,2) DEFAULT 0.00,
    ach_cap DECIMAL(10,2) DEFAULT 0.00,
    card_pct DECIMAL(5,3) DEFAULT 0.000,
    card_flat DECIMAL(5,2) DEFAULT 0.00,
    supports_ach TINYINT DEFAULT 1,
    supports_card TINYINT DEFAULT 0,
    supports_fednow TINYINT DEFAULT 0,
    supports_rtp TINYINT DEFAULT 0,
    best_for TEXT,
    active TINYINT DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_name (name)
) ENGINE=InnoDB;

-- ACH Accounts
CREATE TABLE IF NOT EXISTS ach_accounts (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    label VARCHAR(128) NOT NULL,
    routing_number VARCHAR(9) NOT NULL,
    account_number_encrypted BLOB NOT NULL,
    account_type ENUM('checking','savings') DEFAULT 'checking',
    beneficiary_name VARCHAR(256),
    bank_name VARCHAR(128),
    verified TINYINT DEFAULT 0,
    verification_method VARCHAR(32),
    platform VARCHAR(32),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_label (label)
) ENGINE=InnoDB;

-- ACH Transfers
CREATE TABLE IF NOT EXISTS ach_transfers (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    platform VARCHAR(32) NOT NULL,
    method ENUM('ach','card','fednow','rtp') NOT NULL DEFAULT 'ach',
    speed ENUM('standard','same_day','instant') NOT NULL DEFAULT 'standard',
    direction ENUM('send','receive') NOT NULL DEFAULT 'send',
    amount DECIMAL(12,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',
    fee_amount DECIMAL(10,2) DEFAULT 0.00,
    fee_calculation TEXT,
    routing_number VARCHAR(9),
    beneficiary_name VARCHAR(256),
    memo VARCHAR(256),
    idempotency_key VARCHAR(64),
    platform_reference VARCHAR(128),
    status ENUM('pending','processing','completed','failed','returned') DEFAULT 'pending',
    error_message TEXT,
    initiated_by VARCHAR(64),
    initiated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP NULL,
    INDEX idx_platform (platform),
    INDEX idx_status (status),
    INDEX idx_idempotency (idempotency_key)
) ENGINE=InnoDB;

-- ACH Audit Log
CREATE TABLE IF NOT EXISTS ach_audit_log (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    transfer_id BIGINT,
    event_type VARCHAR(32) NOT NULL,
    event_detail TEXT,
    event_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    actor VARCHAR(64),
    INDEX idx_transfer (transfer_id),
    INDEX idx_event_time (event_time)
) ENGINE=InnoDB;

-- TLS Intelligence (outbound connection key exchange capture)
CREATE TABLE IF NOT EXISTS tls_intelligence (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    hostname VARCHAR(256) NOT NULL,
    port INT NOT NULL,
    protocol VARCHAR(16),
    cipher_suite VARCHAR(128),
    key_exchange_method VARCHAR(128),
    server_cert_subject TEXT,
    server_cert_issuer TEXT,
    server_cert_serial VARCHAR(128),
    public_key_algorithm VARCHAR(16),
    public_key_bits INT,
    public_key_fingerprint VARCHAR(128),
    cert_chain TEXT,
    not_before TIMESTAMP NULL,
    not_after TIMESTAMP NULL,
    captured_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fiduciary_hold_intact TINYINT DEFAULT 1,
    INDEX idx_host_port (hostname, port),
    INDEX idx_fingerprint (public_key_fingerprint),
    INDEX idx_captured (captured_at)
) ENGINE=InnoDB;

-- Outbound connection log (NAT strategy tracking)
CREATE TABLE IF NOT EXISTS outbound_connections (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    hostname VARCHAR(256) NOT NULL,
    port INT NOT NULL,
    protocol VARCHAR(16),
    strategy ENUM('persistent','relay','polling','upnp') NOT NULL DEFAULT 'polling',
    purpose VARCHAR(128),
    connected_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    disconnected_at TIMESTAMP NULL,
    keepalive_count INT DEFAULT 0,
    nat_detected TINYINT DEFAULT 1,
    INDEX idx_host (hostname),
    INDEX idx_strategy (strategy)
) ENGINE=InnoDB;

-- Seed ACH platforms
INSERT IGNORE INTO ach_platforms (name, display_name, api_base_url, monthly_fee, ach_pct, ach_flat, ach_cap, card_pct, card_flat, supports_ach, supports_card, supports_fednow, supports_rtp, best_for) VALUES
    ('melio', 'Melio', 'https://api.melio.com/v1', 0.00, 0.000, 0.00, 0.00, 2.900, 0.30, 1, 1, 0, 0, 'Zero-fee standard business ACH transactions'),
    ('moov', 'Moov', 'https://api.moov.io/v1', 0.00, 0.000, 0.00, 0.00, 0.000, 0.00, 1, 0, 1, 1, 'API-first automated or per-use software integrations'),
    ('stripe', 'Stripe', 'https://api.stripe.com/v1', 0.00, 0.800, 0.00, 5.00, 2.900, 0.30, 1, 1, 0, 0, 'E-commerce web checkouts, custom code integrations, international currencies'),
    ('square', 'Square', 'https://connect.squareup.com/v2', 0.00, 1.000, 0.00, 0.00, 2.900, 0.30, 1, 1, 0, 0, 'Quick invoice links, easy virtual terminals, immediate day-after payouts'),
    ('helcim', 'Helcim', 'https://api.helcim.com/v2', 0.00, 0.500, 0.25, 6.00, 2.270, 0.25, 1, 1, 0, 0, 'Wholesale, B2B invoicing, automated surcharging');
"

echo "[OK] nwe_fiduciary database ready."
echo "     16 tables created."
echo "     ACH platforms seeded: Melio, Moov, Stripe, Square, Helcim."
echo "     TLS intelligence + outbound connections tracked."
echo "     Installer Tech ID: Max Rupplin"
