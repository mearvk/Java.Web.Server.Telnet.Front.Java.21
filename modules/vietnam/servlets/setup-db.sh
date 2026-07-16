#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════════
# NitroWebExpress™ — Vietnam Database Setup
# Creates nwe_vietnam database with fighting_styles + languages tables.
# SAFE: Uses CREATE IF NOT EXISTS. Never drops or overwrites existing data.
# Can be run repeatedly after git pull without risk to production databases.
# ═══════════════════════════════════════════════════════════════════════════════════
set -e

echo "[*] Creating nwe_vietnam database..."

mysql -u root -e "
CREATE DATABASE IF NOT EXISTS nwe_vietnam;
USE nwe_vietnam;

CREATE TABLE IF NOT EXISTS fighting_styles (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(128) NOT NULL,
    region VARCHAR(128),
    era VARCHAR(64),
    description TEXT,
    techniques TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_name (name),
    INDEX idx_region (region)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS languages (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(128) NOT NULL,
    family VARCHAR(128),
    speakers VARCHAR(64),
    script_type VARCHAR(64),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_name (name),
    INDEX idx_family (family)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT IGNORE INTO fighting_styles (id, name, region, era, description, techniques) VALUES
    (1, 'Vovinam', 'Vietnam', '1938-present', 'Founded by Nguyen Loc', 'Scissors kicks, joint locks, weapon forms'),
    (2, 'Viet Vo Dao', 'Vietnam', 'Ancient', 'Umbrella term for Vietnamese martial arts', 'Strikes, grappling, weapons'),
    (3, 'Binh Dinh', 'Central Vietnam', '10th century', 'Regional fighting tradition', 'Staff, sword, animal forms'),
    (4, 'Cuong Nhu', 'Vietnam/USA', '1965-present', 'Hard-soft blend by Ngo Dong', 'Wing Chun, Judo, Tai Chi blend'),
    (5, 'Nhat Nam', 'Northern Vietnam', 'Ancient', 'Northern combat system', 'Internal energy, pressure strikes');

INSERT IGNORE INTO languages (id, name, family, speakers, script_type, notes) VALUES
    (1, 'Vietnamese', 'Austroasiatic', '85 million', 'Latin (Quoc Ngu)', 'Official, 6 tones'),
    (2, 'Tay', 'Tai-Kadai', '1.7 million', 'Latin', 'Northern highlands'),
    (3, 'Muong', 'Austroasiatic', '1.2 million', 'Latin', 'Related to Vietnamese'),
    (4, 'Khmer Krom', 'Austroasiatic', '1 million', 'Khmer script', 'Mekong Delta'),
    (5, 'Cham', 'Austronesian', '100000', 'Cham/Latin', 'Champa kingdom'),
    (6, 'Hmong', 'Hmong-Mien', '1 million', 'RPA Latin', 'Highland dialects');
"

echo "[OK] nwe_vietnam database ready."
