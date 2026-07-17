#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════════
# NitroWebExpress™ — SpectrumTandem Database Setup
# Creates nwe_spectrum_tandem database with word_bank, dolyene_spectrum,
# county_precedent, and revisions tables.
# SAFE: Uses CREATE IF NOT EXISTS. Never drops or overwrites existing data.
# Can be run repeatedly after git pull without risk to production databases.
#
# Installer Tech ID: Max Rupplin
# ═══════════════════════════════════════════════════════════════════════════════════
set -e

echo "[*] Creating nwe_spectrum_tandem database..."

mysql -u root -e "
CREATE DATABASE IF NOT EXISTS nwe_spectrum_tandem;
USE nwe_spectrum_tandem;

-- Word Bank: stores term, definition, specialness, radix, author, timestamps
CREATE TABLE IF NOT EXISTS word_bank (
    id INT AUTO_INCREMENT PRIMARY KEY,
    term VARCHAR(256) NOT NULL,
    definition TEXT,
    specialness VARCHAR(128),
    radix VARCHAR(64),
    spelling_variant VARCHAR(256),
    author_id VARCHAR(128) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_term (term),
    INDEX idx_radix (radix),
    INDEX idx_spelling (spelling_variant),
    INDEX idx_author (author_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Dolyene Spectrum: int discipline indices, spelling conditions, weights
CREATE TABLE IF NOT EXISTS dolyene_spectrum (
    id INT AUTO_INCREMENT PRIMARY KEY,
    word_bank_id INT NOT NULL,
    discipline_index INT NOT NULL,
    int_value INT NOT NULL DEFAULT 0,
    spelling_condition VARCHAR(256),
    weight DOUBLE DEFAULT 1.0,
    radix_condition VARCHAR(64),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (word_bank_id) REFERENCES word_bank(id),
    INDEX idx_word_bank (word_bank_id),
    INDEX idx_discipline (discipline_index)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- County Precedent: full capitalized term of precedent, pointers, indirections
CREATE TABLE IF NOT EXISTS county_precedent (
    id INT AUTO_INCREMENT PRIMARY KEY,
    county VARCHAR(128) NOT NULL,
    pointer VARCHAR(512),
    indirection VARCHAR(512),
    revision_number INT NOT NULL DEFAULT 1,
    caliber VARCHAR(64) DEFAULT 'STANDARD',
    author_id VARCHAR(128) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_county (county),
    INDEX idx_pointer (pointer(255)),
    INDEX idx_caliber (caliber)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Revisions: immutable revision log (NO DELETE, NO UPDATE)
CREATE TABLE IF NOT EXISTS revisions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    word_bank_id INT NOT NULL,
    revision_number INT NOT NULL,
    old_definition TEXT,
    new_definition TEXT,
    revisionist_id VARCHAR(128) NOT NULL,
    revised_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (word_bank_id) REFERENCES word_bank(id),
    INDEX idx_word_bank (word_bank_id),
    INDEX idx_revisionist (revisionist_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Seed word bank
INSERT IGNORE INTO word_bank (id, term, definition, specialness, radix, spelling_variant, author_id) VALUES
    (1, 'dolyene', 'The spectrum of int discipline; the graphical representation of term usage frequency across radix conditions', 'CORE_CONCEPT', 'doly', 'dolyene', 'Max Rupplin'),
    (2, 'spectrum', 'A range or continuum of values representing the spread of a term across its int discipline', 'MEASURE', 'spect', 'spectrum', 'Max Rupplin'),
    (3, 'radix', 'The root or base form of a term from which spelling variants derive', 'LINGUISTIC', 'radix', 'radix', 'Max Rupplin'),
    (4, 'tandem', 'Two or more elements operating in conjunction; parallel execution of spectrum analysis', 'OPERATIONAL', 'tand', 'tandem', 'Max Rupplin'),
    (5, 'int discipline', 'The integer classification system governing term ordering and spectral weight', 'MATHEMATICAL', 'intdi', 'int discipline', 'Max Rupplin'),
    (6, 'pointer', 'A reference to another term or county precedent; indirection target', 'REFERENCE', 'point', 'pointer', 'Max Rupplin'),
    (7, 'indirection', 'A layer of abstraction between a pointer and its final resolution', 'REFERENCE', 'indir', 'indirection', 'Max Rupplin'),
    (8, 'county', 'Full capitalized term of precedent; jurisdictional authority over term definitions', 'GOVERNANCE', 'count', 'COUNTY', 'Max Rupplin'),
    (9, 'caliber', 'The quality or grade of a revision; measure of revision significance', 'QUALITY', 'calib', 'caliber', 'Max Rupplin'),
    (10, 'specialness', 'The categorical classification of a term within the word bank hierarchy', 'META', 'speci', 'specialness', 'Max Rupplin');

-- Seed county precedent
INSERT IGNORE INTO county_precedent (id, county, pointer, indirection, revision_number, caliber, author_id) VALUES
    (1, 'DURHAM', 'dolyene→spectrum', 'word_bank.id=1', 1, 'STANDARD', 'Max Rupplin'),
    (2, 'WAKE', 'radix→spelling_variant', 'word_bank.id=3', 1, 'STANDARD', 'Max Rupplin'),
    (3, 'ORANGE', 'int discipline→discipline_index', 'dolyene_spectrum.discipline_index', 1, 'HIGH', 'Max Rupplin');

-- Seed dolyene spectrum
INSERT IGNORE INTO dolyene_spectrum (id, word_bank_id, discipline_index, int_value, spelling_condition, weight, radix_condition) VALUES
    (1, 1, 1, 100, 'dolyene', 1.0, 'doly'),
    (2, 1, 2, 85, 'Dolyene', 0.85, 'doly'),
    (3, 1, 3, 60, 'DOLYENE', 0.6, 'DOLY'),
    (4, 2, 1, 95, 'spectrum', 1.0, 'spect'),
    (5, 2, 2, 70, 'Spectrum', 0.7, 'Spect'),
    (6, 3, 1, 90, 'radix', 1.0, 'radix'),
    (7, 5, 1, 100, 'int discipline', 1.0, 'intdi'),
    (8, 5, 2, 50, 'INT DISCIPLINE', 0.5, 'INTDI');
"

echo "[OK] nwe_spectrum_tandem database ready."
