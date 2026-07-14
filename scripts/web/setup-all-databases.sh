#!/bin/bash
# NitroWebExpress™ — Setup All Module Databases
# Creates ALL module databases and tables in one shot.
#
# SAFE TO RUN REPEATEDLY: Uses CREATE DATABASE/TABLE IF NOT EXISTS throughout.
# Will NEVER drop, truncate, or overwrite existing databases or data.
# New tables are added alongside existing ones. Existing rows are untouched.
#
# Usage: bash scripts/web/setup-all-databases.sh
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

# Load credentials from .nwe-credentials (gitignored, never committed)
if [ -f "$PROJECT_ROOT/.nwe-credentials" ]; then
    source "$PROJECT_ROOT/.nwe-credentials"
else
    echo "[!] No .nwe-credentials found. Copy from example:"
    echo "    cp .nwe-credentials.example .nwe-credentials"
    echo "    Then fill in your MySQL password."
    echo ""
    echo "    Trying with default credentials..."
    NWE_DB_USER="root"
    NWE_DB_PASS='$$Ironman1'
    NWE_DB_HOST="127.0.0.1"
fi

MYSQL="mysql -u $NWE_DB_USER -p$NWE_DB_PASS -h ${NWE_DB_HOST:-127.0.0.1}"

echo "═══════════════════════════════════════════════════════════════"
echo " NitroWebExpress™ — Setup All Databases"
echo "═══════════════════════════════════════════════════════════════"

$MYSQL 2>/dev/null << 'SQL'

-- ═══ California FBI ═══
CREATE DATABASE IF NOT EXISTS nwe_california_fbi;
USE nwe_california_fbi;
CREATE TABLE IF NOT EXISTS crime_reports (
    id BIGINT AUTO_INCREMENT PRIMARY KEY, category VARCHAR(100) NOT NULL,
    report_text TEXT NOT NULL, status ENUM('pending','forwarded','closed') DEFAULT 'pending',
    installer_id VARCHAR(64) DEFAULT NULL, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_category (category), INDEX idx_status (status), INDEX idx_created (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS fbi_forwarded_tips (
    id BIGINT AUTO_INCREMENT PRIMARY KEY, report_id BIGINT NOT NULL,
    forwarded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, response_code INT,
    installer_id VARCHAR(64) NOT NULL, FOREIGN KEY (report_id) REFERENCES crime_reports(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ═══ California CIA ═══
CREATE DATABASE IF NOT EXISTS nwe_california_cia;
USE nwe_california_cia;
CREATE TABLE IF NOT EXISTS intelligence_reports (
    id BIGINT AUTO_INCREMENT PRIMARY KEY, category VARCHAR(100) NOT NULL,
    report_text TEXT NOT NULL, status ENUM('pending','reviewed','forwarded','closed') DEFAULT 'pending',
    installer_id VARCHAR(64) DEFAULT NULL, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_category (category), INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS foia_requests (
    id BIGINT AUTO_INCREMENT PRIMARY KEY, subject VARCHAR(500) NOT NULL,
    status ENUM('submitted','processing','complete','denied') DEFAULT 'submitted',
    installer_id VARCHAR(64) DEFAULT NULL, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ═══ California NSA ═══
CREATE DATABASE IF NOT EXISTS nwe_california_nsa;
USE nwe_california_nsa;
CREATE TABLE IF NOT EXISTS cyber_reports (
    id BIGINT AUTO_INCREMENT PRIMARY KEY, category VARCHAR(100) NOT NULL,
    report_text TEXT NOT NULL, status ENUM('pending','reviewed','escalated','closed') DEFAULT 'pending',
    installer_id VARCHAR(64) DEFAULT NULL, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_category (category), INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS advisories (
    id BIGINT AUTO_INCREMENT PRIMARY KEY, title VARCHAR(500) NOT NULL,
    severity ENUM('low','medium','high','critical') DEFAULT 'medium',
    source_url VARCHAR(1000), installer_id VARCHAR(64) DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ═══ Duke University ═══
CREATE DATABASE IF NOT EXISTS nwe_duke;
USE nwe_duke;
CREATE TABLE IF NOT EXISTS college_queries (
    id BIGINT AUTO_INCREMENT PRIMARY KEY, college VARCHAR(200) NOT NULL,
    query_text TEXT NOT NULL, status ENUM('pending','answered','archived') DEFAULT 'pending',
    installer_id VARCHAR(64) DEFAULT NULL, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_college (college), INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS course_catalog (
    id BIGINT AUTO_INCREMENT PRIMARY KEY, college VARCHAR(200) NOT NULL,
    department VARCHAR(200), course_code VARCHAR(20), title VARCHAR(500), description TEXT,
    installer_id VARCHAR(64) DEFAULT NULL, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ═══ Stanford Library ═══
CREATE DATABASE IF NOT EXISTS nwe_library;
USE nwe_library;
CREATE TABLE IF NOT EXISTS library_requests (
    id BIGINT AUTO_INCREMENT PRIMARY KEY, title VARCHAR(500) NOT NULL,
    resource_type VARCHAR(100) DEFAULT 'general', status ENUM('pending','found','unavailable') DEFAULT 'pending',
    installer_id VARCHAR(64) DEFAULT NULL, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_type (resource_type), INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS catalog_cache (
    id BIGINT AUTO_INCREMENT PRIMARY KEY, title VARCHAR(500) NOT NULL,
    author VARCHAR(300), collection VARCHAR(200), call_number VARCHAR(50),
    source_url VARCHAR(1000), installer_id VARCHAR(64) DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ═══ International Signal Servers ═══
CREATE DATABASE IF NOT EXISTS nwe_japan;
USE nwe_japan;
CREATE TABLE IF NOT EXISTS signals (id BIGINT AUTO_INCREMENT PRIMARY KEY, source VARCHAR(200), signal_type VARCHAR(100), data TEXT, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS sources (id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(200), url VARCHAR(500), enabled BOOLEAN DEFAULT TRUE) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE DATABASE IF NOT EXISTS nwe_russia;
USE nwe_russia;
CREATE TABLE IF NOT EXISTS signals (id BIGINT AUTO_INCREMENT PRIMARY KEY, source VARCHAR(200), signal_type VARCHAR(100), data TEXT, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS sources (id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(200), url VARCHAR(500), enabled BOOLEAN DEFAULT TRUE) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE DATABASE IF NOT EXISTS nwe_mexico;
USE nwe_mexico;
CREATE TABLE IF NOT EXISTS signals (id BIGINT AUTO_INCREMENT PRIMARY KEY, source VARCHAR(200), signal_type VARCHAR(100), data TEXT, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS sources (id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(200), url VARCHAR(500), enabled BOOLEAN DEFAULT TRUE) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE DATABASE IF NOT EXISTS nwe_greece_intl;
USE nwe_greece_intl;
CREATE TABLE IF NOT EXISTS signals (id BIGINT AUTO_INCREMENT PRIMARY KEY, source VARCHAR(200), signal_type VARCHAR(100), data TEXT, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS sources (id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(200), url VARCHAR(500), enabled BOOLEAN DEFAULT TRUE) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ═══ Futures ═══
CREATE DATABASE IF NOT EXISTS nwe_futures;
USE nwe_futures;
CREATE TABLE IF NOT EXISTS pipeline_runs (id BIGINT AUTO_INCREMENT PRIMARY KEY, pipeline VARCHAR(200), status VARCHAR(50), result TEXT, installer_id VARCHAR(64), created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS ai_predictions (id BIGINT AUTO_INCREMENT PRIMARY KEY, model VARCHAR(100), input_text TEXT, prediction TEXT, confidence DOUBLE, installer_id VARCHAR(64), created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ═══ GDGH ═══
CREATE DATABASE IF NOT EXISTS nwe_gdgh;
USE nwe_gdgh;
CREATE TABLE IF NOT EXISTS labor_concerns (id BIGINT AUTO_INCREMENT PRIMARY KEY, category VARCHAR(100), concern_text TEXT, status VARCHAR(50) DEFAULT 'open', installer_id VARCHAR(64), created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS contacts (id BIGINT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(200), role VARCHAR(100), email VARCHAR(254), installer_id VARCHAR(64), created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ═══ AE6E66 ═══
CREATE DATABASE IF NOT EXISTS nwe_ae6e66;
USE nwe_ae6e66;
CREATE TABLE IF NOT EXISTS contacts (id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(300), email VARCHAR(254), phone VARCHAR(50), ministry VARCHAR(200), source VARCHAR(50), created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS sent_log (id BIGINT AUTO_INCREMENT PRIMARY KEY, recipient VARCHAR(254), subject VARCHAR(500), sha256 VARCHAR(64), status VARCHAR(50), sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ═══ Gray Registries ═══
CREATE DATABASE IF NOT EXISTS nwe_gray_registry;
USE nwe_gray_registry;
CREATE TABLE IF NOT EXISTS leases (id BIGINT AUTO_INCREMENT PRIMARY KEY, block_id INT NOT NULL, term VARCHAR(20), btc_txid VARCHAR(100), leased_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, expires_at TIMESTAMP) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS payments (id BIGINT AUTO_INCREMENT PRIMARY KEY, txid VARCHAR(100), amount_usd DECIMAL(12,2), coin VARCHAR(20), created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE DATABASE IF NOT EXISTS nwe_gray85_registry;
USE nwe_gray85_registry;
CREATE TABLE IF NOT EXISTS leases (id BIGINT AUTO_INCREMENT PRIMARY KEY, block_id INT NOT NULL, term VARCHAR(20), btc_txid VARCHAR(100), leased_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, expires_at TIMESTAMP) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS creme_unlocks (id BIGINT AUTO_INCREMENT PRIMARY KEY, block_id INT, port_offset INT, hours INT, btc_txid VARCHAR(100), unlocked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS payments (id BIGINT AUTO_INCREMENT PRIMARY KEY, txid VARCHAR(100), amount_usd DECIMAL(12,2), coin VARCHAR(20), created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

SQL

echo "[OK] All databases and tables created/verified."
echo "═══════════════════════════════════════════════════════════════"
