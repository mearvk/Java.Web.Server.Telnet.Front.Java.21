#!/bin/bash
# AE6E66™ — Setup MySQL Database
# Creates nwe_ae6e66 database and tables
# Usage: bash modules/AE6E66/servlets/setup-db.sh
set -e

DB_USER="root"
DB_PASS='$$Ironman1'
DB_HOST="127.0.0.1"
DB_NAME="nwe_ae6e66"
MYSQL="mysql -u$DB_USER -p$DB_PASS -h$DB_HOST"

echo "═══════════════════════════════════════════════════════════════"
echo " AE6E66™ — Setup Database"
echo "═══════════════════════════════════════════════════════════════"

$MYSQL <<SQL
CREATE DATABASE IF NOT EXISTS $DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE $DB_NAME;

CREATE TABLE IF NOT EXISTS contacts (
    id INT PRIMARY KEY,
    name VARCHAR(255),
    email VARCHAR(255),
    phone VARCHAR(100),
    ministry VARCHAR(255),
    gender VARCHAR(20),
    age VARCHAR(10),
    source VARCHAR(10),
    career TEXT,
    crawled_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_source (source),
    INDEX idx_ministry (ministry)
);

CREATE TABLE IF NOT EXISTS sent_log (
    id INT AUTO_INCREMENT PRIMARY KEY,
    recipient VARCHAR(255) NOT NULL,
    sha256 CHAR(64),
    status VARCHAR(20),
    message_file VARCHAR(255),
    sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_recipient (recipient),
    INDEX idx_status (status)
);

CREATE TABLE IF NOT EXISTS crawl_history (
    id INT AUTO_INCREMENT PRIMARY KEY,
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP NULL,
    members_found INT DEFAULT 0,
    portraits_downloaded INT DEFAULT 0,
    duration_seconds INT DEFAULT 0
);
SQL

echo "[✓] Database $DB_NAME ready"

# Import contacts.csv if table is empty
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
AE6E66_ROOT="$(dirname "$SCRIPT_DIR")"
CSV="$AE6E66_ROOT/contacts.csv"
COUNT=$($MYSQL -N -e "SELECT COUNT(*) FROM $DB_NAME.contacts;" 2>/dev/null)

if [ "$COUNT" -eq 0 ] 2>/dev/null && [ -f "$CSV" ]; then
    echo "[*] Importing contacts.csv..."
    tail -n +2 "$CSV" | grep -v "^#" | while IFS=',' read -r id name email phone ministry gender age source career; do
        name="${name//\'/\\\'}"
        email="${email//\'/\\\'}"
        ministry="${ministry//\'/\\\'}"
        career="${career//\'/\\\'}"
        $MYSQL -e "INSERT IGNORE INTO $DB_NAME.contacts (id,name,email,phone,ministry,gender,age,source,career) VALUES($id,'$name','$email','$phone','$ministry','$gender','$age','$source','$career');" 2>/dev/null
    done
    FINAL=$($MYSQL -N -e "SELECT COUNT(*) FROM $DB_NAME.contacts;" 2>/dev/null)
    echo "[✓] Imported $FINAL contacts"
else
    echo "[*] Contacts table has $COUNT rows (skipping import)"
fi

echo "═══════════════════════════════════════════════════════════════"
