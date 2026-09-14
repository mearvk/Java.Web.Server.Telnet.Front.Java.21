#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════════
# Brarner.M.Alete™ — Science Input Analytics Table Setup
# Creates bma_science_inputs table in nwe_analytics for tracking inputs,
# communications, posts, and downloads across BMA categories.
# SAFE: Uses CREATE IF NOT EXISTS.
# ═══════════════════════════════════════════════════════════════════════════════════
set -e

echo "[*] Creating BMA science input tables in nwe_analytics..."

mysql -u root -e "
CREATE DATABASE IF NOT EXISTS nwe_analytics;
USE nwe_analytics;

-- ───────────────────────────────────────────────────────────────────────
-- BMA Science Inputs: daily counts per category per metric type
-- Categories: SSA, Species, PostOffice, Science, Art, Legal, Analysis
-- ───────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS bma_science_inputs (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    category VARCHAR(32) NOT NULL,
    activity_date DATE NOT NULL,
    input_count INT DEFAULT 0,
    comm_count INT DEFAULT 0,
    post_count INT DEFAULT 0,
    download_count INT DEFAULT 0,
    unique_users INT DEFAULT 0,
    INDEX idx_category (category),
    INDEX idx_date (activity_date),
    UNIQUE KEY uk_cat_date (category, activity_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ───────────────────────────────────────────────────────────────────────
-- BMA Science Input Log: individual input events (granular)
-- ───────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS bma_input_log (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    category VARCHAR(32) NOT NULL,
    event_type ENUM('input', 'comm', 'post', 'download') NOT NULL,
    user_hash VARCHAR(64),
    ip_address VARCHAR(45),
    description VARCHAR(512),
    metadata TEXT,
    event_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_category (category),
    INDEX idx_type (event_type),
    INDEX idx_event_at (event_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ───────────────────────────────────────────────────────────────────────
-- BMA Category Registry
-- ───────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS bma_categories (
    id INT AUTO_INCREMENT PRIMARY KEY,
    category_key VARCHAR(32) NOT NULL UNIQUE,
    display_name VARCHAR(64) NOT NULL,
    color VARCHAR(16) NOT NULL,
    description VARCHAR(255),
    related_db VARCHAR(64),
    related_table VARCHAR(64),
    is_active BOOLEAN DEFAULT TRUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT IGNORE INTO bma_categories (category_key, display_name, color, description, related_db, related_table) VALUES
    ('SSA', 'SSA', '#f59e0b', 'Social Security Administration data inputs', 'BrarnerScience', 'publications'),
    ('Species', 'Species', '#22c55e', 'Species taxonomy, animalia, biodiversity entries', 'BrarnerScience', 'species'),
    ('PostOffice', 'Post Office', '#ef4444', 'Postal codes, office data, experiments', 'BrarnerPostal', 'postal_offices'),
    ('Science', 'Science', '#3b82f6', 'Scientific publications, DOI, experiments', 'BrarnerScience', 'publications'),
    ('Art', 'Art', '#a855f7', 'Art institutions, collections, museum data', 'BrarnerArt', 'art_collection'),
    ('Legal', 'Legal', '#06b6d4', 'Legal database inputs, case law, precedent', 'BrarnerScience', NULL),
    ('Analysis', 'Analysis', '#ec4899', 'Taxonomy analysis, file uploads, classification', 'BrarnerScience', NULL);
"

echo "[OK] BMA science input tables ready."
echo "     Tables: bma_science_inputs, bma_input_log, bma_categories"
echo ""
echo "     Recording inputs from Java backend:"
echo "       INSERT INTO nwe_analytics.bma_science_inputs (category, activity_date, input_count)"
echo "       VALUES ('Species', CURDATE(), 1)"
echo "       ON DUPLICATE KEY UPDATE input_count = input_count + 1;"
