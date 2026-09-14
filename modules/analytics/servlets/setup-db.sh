#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════════
# NitroWebExpress™ — Analytics Database Setup
# Creates nwe_analytics database for traffic graphing (GitHub-style).
# Tracks: page views, unique visitors, uploads, new users, module activity.
# SAFE: Uses CREATE IF NOT EXISTS. Never drops or overwrites existing data.
# Installer Tech ID: Max Rupplin
# ═══════════════════════════════════════════════════════════════════════════════════
set -e

echo "[*] Creating nwe_analytics database..."

mysql -u root -e "
CREATE DATABASE IF NOT EXISTS nwe_analytics;
USE nwe_analytics;

-- ───────────────────────────────────────────────────────────────────────
-- Page Views: total + unique per day per module (like GitHub traffic graph)
-- ───────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS page_views (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    module_name VARCHAR(64) NOT NULL,
    view_date DATE NOT NULL,
    total_views INT DEFAULT 0,
    unique_visitors INT DEFAULT 0,
    INDEX idx_module (module_name),
    INDEX idx_date (view_date),
    UNIQUE KEY uk_module_date (module_name, view_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ───────────────────────────────────────────────────────────────────────
-- Visitor Log: individual visits with IP fingerprint (hashed)
-- ───────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS visitor_log (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    module_name VARCHAR(64) NOT NULL,
    visitor_hash VARCHAR(64) NOT NULL,
    ip_address VARCHAR(45),
    user_agent VARCHAR(512),
    page_path VARCHAR(256),
    referrer VARCHAR(512),
    visited_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_module (module_name),
    INDEX idx_hash (visitor_hash),
    INDEX idx_visited (visited_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ───────────────────────────────────────────────────────────────────────
-- New Users: registrations per day per module
-- ───────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS new_users (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    module_name VARCHAR(64) NOT NULL,
    register_date DATE NOT NULL,
    user_count INT DEFAULT 0,
    INDEX idx_module (module_name),
    INDEX idx_date (register_date),
    UNIQUE KEY uk_module_date (module_name, register_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ───────────────────────────────────────────────────────────────────────
-- Uploads: file uploads per day per module (files, voice, images)
-- ───────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS uploads (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    module_name VARCHAR(64) NOT NULL,
    upload_date DATE NOT NULL,
    upload_count INT DEFAULT 0,
    total_bytes BIGINT DEFAULT 0,
    INDEX idx_module (module_name),
    INDEX idx_date (upload_date),
    UNIQUE KEY uk_module_date (module_name, upload_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ───────────────────────────────────────────────────────────────────────
-- Clones / Downloads: git clone equivalents (source fetches, doc downloads)
-- ───────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS clones (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    module_name VARCHAR(64) NOT NULL,
    clone_date DATE NOT NULL,
    total_clones INT DEFAULT 0,
    unique_cloners INT DEFAULT 0,
    INDEX idx_module (module_name),
    INDEX idx_date (clone_date),
    UNIQUE KEY uk_module_date (module_name, clone_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ───────────────────────────────────────────────────────────────────────
-- Referring Sites: where traffic comes from
-- ───────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS referring_sites (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    module_name VARCHAR(64) NOT NULL,
    referrer_domain VARCHAR(256) NOT NULL,
    ref_date DATE NOT NULL,
    visit_count INT DEFAULT 0,
    unique_visitors INT DEFAULT 0,
    INDEX idx_module (module_name),
    INDEX idx_date (ref_date),
    UNIQUE KEY uk_module_ref_date (module_name, referrer_domain(128), ref_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ───────────────────────────────────────────────────────────────────────
-- Popular Content: most visited pages per module
-- ───────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS popular_content (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    module_name VARCHAR(64) NOT NULL,
    page_path VARCHAR(256) NOT NULL,
    content_date DATE NOT NULL,
    view_count INT DEFAULT 0,
    unique_visitors INT DEFAULT 0,
    INDEX idx_module (module_name),
    INDEX idx_date (content_date),
    UNIQUE KEY uk_module_page_date (module_name, page_path(128), content_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ───────────────────────────────────────────────────────────────────────
-- Module Registry: all tracked modules
-- ───────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS modules (
    id INT AUTO_INCREMENT PRIMARY KEY,
    module_name VARCHAR(64) NOT NULL UNIQUE,
    context_path VARCHAR(128),
    theme_color VARCHAR(16),
    tcp_port VARCHAR(64),
    database_name VARCHAR(64),
    is_active BOOLEAN DEFAULT TRUE,
    registered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Pre-register all JWSTF modules
INSERT IGNORE INTO modules (module_name, context_path, theme_color, tcp_port, database_name) VALUES
    ('Brarner.M.Alete', '/brarner.m.alete', '#3b82f6', NULL, 'BrarnerScience'),
    ('AE6E66', '/ae6e66', '#22c55e', NULL, 'nwe_ae6e66'),
    ('Futures', '/futures', '#ef4444', '5000', 'nwe_futures'),
    ('Green.Durham.Grass.and.Herb', '/gdgh', '#16a34a', '2000,20000,40002-7,49152', 'nwe_gdgh'),
    ('GrayPortRegistry', '/gray-registry', '#6b7280', '9999', 'nwe_gray_registry'),
    ('Gray85Creme', '/gray85-registry', '#d97706', '10085', 'nwe_gray85_registry'),
    ('BlackBelt', '/blackbelt', '#f5f5f5', NULL, 'nwe_blackbelt'),
    ('Languages', '/languages', '#8b5cf6', NULL, 'nwe_languages'),
    ('Strernary', '/strernary', '#06b6d4', '20000,2000', 'nwe_strernary'),
    ('Vietnam', '/vietnam', '#a0826d', '49215', 'nwe_vietnam'),
    ('Emeter', '/emeter', '#7dd3fc', '49216', 'nwe_emeter'),
    ('SpectrumTandem', '/spectrum-tandem', '#cc0000', '49222', 'nwe_spectrum_tandem'),
    ('Communicator', '/chat', '#4a6cf7', '49230', 'nwe_chat'),
    ('UNCW', '/uncw', '#00727A', '49231', 'nwe_uncw');
"

echo "[OK] nwe_analytics database ready (7 tables, 14 modules registered)."
