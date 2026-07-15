#!/bin/bash
# ⚠️  DESTRUCTIVE: This script TRUNCATES/DROPS tables before reloading data.
# Do NOT run as part of git-pull automation. Run manually only when reloading reference data.
# Brarner.M.Alete™ — Populate Legal Database from CSV/RDNS data
# Creates legal tables and loads US Code, case law, precedent, public laws, counts
# Usage: bash install/populate-legal.sh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BMA_ROOT="$(dirname "$SCRIPT_DIR")"
DB_PROPS="$BMA_ROOT/servlets/servlet/src/main/webapp/WEB-INF/db.properties"
LEGAL_SAFE="$BMA_ROOT/data/legal/safe"

echo "═══════════════════════════════════════════════════════════════"
echo " Brarner.M.Alete™ — Populate Legal Database"
echo "═══════════════════════════════════════════════════════════════"

# Read DB credentials
if [ -f "$DB_PROPS" ]; then
    DB_USER=$(grep '^db.user=' "$DB_PROPS" | cut -d= -f2-)
    DB_PASS=$(grep '^db.password=' "$DB_PROPS" | cut -d= -f2-)
    DB_HOST=$(grep '^db.url=' "$DB_PROPS" | sed -n 's|.*://\([^:/]*\).*|\1|p')
    DB_PORT=$(grep '^db.url=' "$DB_PROPS" | sed -n 's|.*:\([0-9]*\)/.*|\1|p')
    DB_HOST="${DB_HOST:-127.0.0.1}"
    DB_PORT="${DB_PORT:-3306}"
    MYSQL_OPTS="-u${DB_USER} -h${DB_HOST} -P${DB_PORT}"
    [ -n "$DB_PASS" ] && MYSQL_OPTS="$MYSQL_OPTS -p${DB_PASS}"
    echo "[*] Credentials from db.properties (user=$DB_USER, host=$DB_HOST:$DB_PORT)"
else
    echo "[!] db.properties not found. Run install.sh first."
    exit 1
fi

# Verify legal safe data exists
if [ ! -d "$LEGAL_SAFE" ]; then
    echo "[!] Legal safe data not found at: $LEGAL_SAFE"
    echo "    Run first: bash data/legal/download-legal-data.sh && bash data/legal/unzip-and-consume.sh"
    exit 1
fi
echo "[*] Legal safe data: $LEGAL_SAFE"

# ============================================================================
# Step 1: Create database and tables
# ============================================================================
echo ""
echo "[1/5] Creating BrarnerScience legal tables..."

mysql $MYSQL_OPTS <<'SQL'
CREATE DATABASE IF NOT EXISTS BrarnerScience;
USE BrarnerScience;

-- US Code titles (54 titles)
CREATE TABLE IF NOT EXISTS legal_usc_titles (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title_number INT NOT NULL,
    title_name VARCHAR(255) NOT NULL,
    approx_sections INT DEFAULT 0,
    positive_law ENUM('yes','no') DEFAULT 'no',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_title_number (title_number),
    INDEX idx_positive_law (positive_law)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Landmark precedent cases
CREATE TABLE IF NOT EXISTS legal_precedent (
    id INT AUTO_INCREMENT PRIMARY KEY,
    case_name VARCHAR(255) NOT NULL,
    citation VARCHAR(100) NOT NULL,
    year_decided INT NOT NULL,
    court VARCHAR(50) NOT NULL,
    category VARCHAR(100),
    significance TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_citation (citation),
    INDEX idx_year (year_decided),
    INDEX idx_category (category),
    INDEX idx_court (court)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Public law counts by Congress
CREATE TABLE IF NOT EXISTS legal_public_law_counts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    congress INT NOT NULL,
    years VARCHAR(20) NOT NULL,
    public_laws_enacted INT DEFAULT 0,
    private_laws_enacted INT DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_congress (congress),
    INDEX idx_public_laws (public_laws_enacted)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Court opinion counts
CREATE TABLE IF NOT EXISTS legal_court_opinion_counts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    court_code VARCHAR(20) NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    total_opinions INT DEFAULT 0,
    earliest_year INT,
    latest_year INT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_court_code (court_code),
    INDEX idx_total_opinions (total_opinions)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- USC title section counts (top-level summary)
CREATE TABLE IF NOT EXISTS legal_usc_title_counts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title_number VARCHAR(20) NOT NULL,
    title_name VARCHAR(255) NOT NULL,
    sections INT DEFAULT 0,
    chapters INT DEFAULT 0,
    positive_law ENUM('yes','no') DEFAULT 'no',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_title (title_number)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

SQL

echo "    [OK] Tables created: legal_usc_titles, legal_precedent, legal_public_law_counts,"
echo "         legal_court_opinion_counts, legal_usc_title_counts"

# ============================================================================
# Step 2: Load US Code titles
# ============================================================================
echo ""
echo "[2/5] Loading US Code titles (uscode-summary.csv)..."

USC_FILE="$LEGAL_SAFE/uscode-summary.csv"
if [ -f "$USC_FILE" ]; then
    # Skip header row, parse CSV
    tail -n +2 "$USC_FILE" | while IFS=',' read -r title_num title_name approx_sections positive_law; do
        # Escape single quotes in title_name
        title_name=$(echo "$title_name" | sed "s/'/''/g")
        mysql $MYSQL_OPTS -e "
            INSERT INTO BrarnerScience.legal_usc_titles (title_number, title_name, approx_sections, positive_law)
            VALUES ($title_num, '$title_name', $approx_sections, '$positive_law')
            ON DUPLICATE KEY UPDATE title_name='$title_name', approx_sections=$approx_sections, positive_law='$positive_law';
        " 2>/dev/null
    done
    COUNT=$(mysql $MYSQL_OPTS -N -B -e "SELECT COUNT(*) FROM BrarnerScience.legal_usc_titles;" 2>/dev/null)
    echo "    [OK] $COUNT USC titles loaded"
else
    echo "    [SKIP] uscode-summary.csv not found"
fi

# ============================================================================
# Step 3: Load landmark precedent cases
# ============================================================================
echo ""
echo "[3/5] Loading landmark precedent cases (landmark-cases.csv)..."

PREC_FILE="$LEGAL_SAFE/landmark-cases.csv"
if [ -f "$PREC_FILE" ]; then
    tail -n +2 "$PREC_FILE" | while IFS=',' read -r case_name citation year court category significance; do
        case_name=$(echo "$case_name" | sed "s/'/''/g")
        citation=$(echo "$citation" | sed "s/'/''/g")
        significance=$(echo "$significance" | sed "s/'/''/g")
        mysql $MYSQL_OPTS -e "
            INSERT INTO BrarnerScience.legal_precedent (case_name, citation, year_decided, court, category, significance)
            VALUES ('$case_name', '$citation', $year, '$court', '$category', '$significance')
            ON DUPLICATE KEY UPDATE case_name='$case_name', year_decided=$year, category='$category', significance='$significance';
        " 2>/dev/null
    done
    COUNT=$(mysql $MYSQL_OPTS -N -B -e "SELECT COUNT(*) FROM BrarnerScience.legal_precedent;" 2>/dev/null)
    echo "    [OK] $COUNT precedent cases loaded"
else
    echo "    [SKIP] landmark-cases.csv not found"
fi

# ============================================================================
# Step 4: Load public law counts
# ============================================================================
echo ""
echo "[4/5] Loading public law counts (public-law-counts.csv)..."

PLAW_FILE="$LEGAL_SAFE/public-law-counts.csv"
if [ -f "$PLAW_FILE" ]; then
    tail -n +2 "$PLAW_FILE" | while IFS=',' read -r congress years public_laws private_laws; do
        mysql $MYSQL_OPTS -e "
            INSERT INTO BrarnerScience.legal_public_law_counts (congress, years, public_laws_enacted, private_laws_enacted)
            VALUES ($congress, '$years', $public_laws, $private_laws)
            ON DUPLICATE KEY UPDATE years='$years', public_laws_enacted=$public_laws, private_laws_enacted=$private_laws;
        " 2>/dev/null
    done
    COUNT=$(mysql $MYSQL_OPTS -N -B -e "SELECT COUNT(*) FROM BrarnerScience.legal_public_law_counts;" 2>/dev/null)
    echo "    [OK] $COUNT congress records loaded"
else
    echo "    [SKIP] public-law-counts.csv not found"
fi

# ============================================================================
# Step 5: Load court opinion counts
# ============================================================================
echo ""
echo "[5/5] Loading court opinion counts (court-opinion-counts.csv)..."

COURT_FILE="$LEGAL_SAFE/court-opinion-counts.csv"
if [ -f "$COURT_FILE" ]; then
    tail -n +2 "$COURT_FILE" | while IFS=',' read -r court_code full_name total_opinions earliest latest; do
        full_name=$(echo "$full_name" | sed "s/'/''/g")
        mysql $MYSQL_OPTS -e "
            INSERT INTO BrarnerScience.legal_court_opinion_counts (court_code, full_name, total_opinions, earliest_year, latest_year)
            VALUES ('$court_code', '$full_name', $total_opinions, $earliest, $latest)
            ON DUPLICATE KEY UPDATE full_name='$full_name', total_opinions=$total_opinions, earliest_year=$earliest, latest_year=$latest;
        " 2>/dev/null
    done
    COUNT=$(mysql $MYSQL_OPTS -N -B -e "SELECT COUNT(*) FROM BrarnerScience.legal_court_opinion_counts;" 2>/dev/null)
    echo "    [OK] $COUNT court records loaded"
else
    echo "    [SKIP] court-opinion-counts.csv not found"
fi

# ============================================================================
# Summary
# ============================================================================
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo " [✓] Legal database populated"
echo ""
echo "     Tables:"
mysql $MYSQL_OPTS -N -B -e "
    SELECT CONCAT('       ', table_name, ' = ', table_rows, ' rows')
    FROM information_schema.tables
    WHERE table_schema='BrarnerScience' AND table_name LIKE 'legal_%';
" 2>/dev/null
echo ""
echo "     Database: BrarnerScience"
echo "     Verify:   mysql -u$DB_USER -h$DB_HOST BrarnerScience -e 'SELECT * FROM legal_precedent LIMIT 5;'"
echo "═══════════════════════════════════════════════════════════════"
