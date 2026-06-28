#!/bin/bash
# AE6E66 — MySQL Setup for macOS
# Uses Homebrew MySQL. Same schema as Linux version.
set -euo pipefail

DB_NAME="nwe_ae6e66"
DB_USER="ae6e66_svc"
DB_PASS=$(openssl rand -base64 24)

echo "-- : [AE6E66] macOS MySQL Setup: ${DB_NAME}"

# Check/install MySQL via Homebrew
if ! command -v mysql &>/dev/null; then
    if command -v brew &>/dev/null; then
        echo "-- : [AE6E66] Installing MySQL via Homebrew..."
        brew install mysql
        brew services start mysql
        sleep 2
    else
        echo "ERROR: MySQL not found and Homebrew not available."
        exit 1
    fi
fi

# Ensure MySQL is running
if ! brew services list 2>/dev/null | grep -q "mysql.*started"; then
    brew services start mysql
    sleep 2
fi

mysql -u root <<SQL
CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\`
    CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';
GRANT SELECT, INSERT, UPDATE ON \`${DB_NAME}\`.* TO '${DB_USER}'@'localhost';
FLUSH PRIVILEGES;

USE \`${DB_NAME}\`;

CREATE TABLE IF NOT EXISTS contacts (
    id INT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(254),
    phone VARCHAR(64),
    ministry VARCHAR(255),
    source ENUM('HOL','HOC','HOC-Enquiries') NOT NULL,
    career TEXT,
    crawl_date DATE NOT NULL,
    INDEX idx_source (source),
    INDEX idx_ministry (ministry)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS sent_log (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    recipient VARCHAR(254) NOT NULL,
    subject VARCHAR(255) NOT NULL,
    sha256 CHAR(64) NOT NULL,
    sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status ENUM('success','failure') NOT NULL,
    error_msg VARCHAR(512),
    INDEX idx_sent_at (sent_at),
    INDEX idx_recipient (recipient)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS crawl_history (
    id INT AUTO_INCREMENT PRIMARY KEY,
    crawl_date DATE NOT NULL,
    hol_count INT DEFAULT 0,
    hoc_count INT DEFAULT 0,
    total_portraits INT DEFAULT 0,
    duration_seconds INT,
    UNIQUE INDEX idx_crawl_date (crawl_date)
) ENGINE=InnoDB;
SQL

# Save credentials
CRED_FILE="modules/AE6E66/configuration/.db-credentials"
cat > "${CRED_FILE}" <<EOF
db.name=${DB_NAME}
db.user=${DB_USER}
db.pass=${DB_PASS}
db.host=localhost
db.port=3306
EOF
chmod 600 "${CRED_FILE}"

echo "-- : [AE6E66] Database ${DB_NAME} created (Homebrew MySQL)."
echo "-- : [AE6E66] User: ${DB_USER} (SELECT, INSERT, UPDATE only)"
echo "-- : [AE6E66] Credentials: ${CRED_FILE} (chmod 600)"
