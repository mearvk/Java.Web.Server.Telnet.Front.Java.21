#!/bin/bash
# Brarner.M.Alete™ — Install MySQL + Create Tables (Linux)
# Installs MySQL if not present, creates BrarnerScience DB and all tables.
# Usage: sudo bash install/install-mysql-linux.sh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BMA_ROOT="$(dirname "$SCRIPT_DIR")"
DB_PROPS="$BMA_ROOT/servlets/servlet/src/main/webapp/WEB-INF/db.properties"

echo "═══════════════════════════════════════════════════════════════"
echo " Brarner.M.Alete™ — MySQL Install (Linux)"
echo "═══════════════════════════════════════════════════════════════"

# Install MySQL if not present
if ! command -v mysql &>/dev/null; then
    echo "[*] Installing MySQL..."
    if command -v apt-get &>/dev/null; then
        export DEBIAN_FRONTEND=noninteractive
        apt-get update -qq
        apt-get install -y -qq mysql-server mysql-client
    elif command -v dnf &>/dev/null; then
        dnf install -y mysql-server mysql
    elif command -v yum &>/dev/null; then
        yum install -y mysql-server mysql
    else
        echo "[!] No supported package manager found. Install MySQL manually."
        exit 1
    fi
    echo "[OK] MySQL installed"
else
    echo "[*] MySQL already installed: $(mysql --version | head -1)"
fi

# Start MySQL
systemctl enable mysql 2>/dev/null || systemctl enable mysqld 2>/dev/null || true
systemctl start mysql 2>/dev/null || systemctl start mysqld 2>/dev/null || true
echo "[OK] MySQL running"

# Read or prompt credentials
if [ -f "$DB_PROPS" ]; then
    DB_USER=$(grep '^db.user=' "$DB_PROPS" | cut -d= -f2-)
    DB_PASS=$(grep '^db.password=' "$DB_PROPS" | cut -d= -f2-)
    echo "[*] Using credentials from db.properties (user=$DB_USER)"
else
    read -rp "    MySQL admin username [root]: " DB_USER
    DB_USER="${DB_USER:-root}"
    read -rsp "    MySQL admin password: " DB_PASS
    echo ""
fi

MYSQL_CMD="mysql -u${DB_USER}"
[ -n "$DB_PASS" ] && MYSQL_CMD="$MYSQL_CMD -p${DB_PASS}"

# Create database and set root password for JDBC
echo "[*] Creating database and configuring root access..."
$MYSQL_CMD <<'SQL'
CREATE DATABASE IF NOT EXISTS BrarnerScience CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$$Ironman1';
FLUSH PRIVILEGES;
SQL

# Create all tables
echo "[*] Creating tables..."
$MYSQL_CMD BrarnerScience <<'SQL'
CREATE TABLE IF NOT EXISTS animalia (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    kingdom VARCHAR(100),
    phylum VARCHAR(100),
    subphylum VARCHAR(100),
    class_name VARCHAR(100),
    subclass VARCHAR(100),
    order_name VARCHAR(100),
    suborder VARCHAR(100),
    infraorder VARCHAR(100),
    family_name VARCHAR(100),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_kingdom (kingdom),
    INDEX idx_class (class_name),
    INDEX idx_order (order_name),
    INDEX idx_family (family_name)
);

CREATE TABLE IF NOT EXISTS species (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    kingdom VARCHAR(100),
    phylum VARCHAR(100),
    class_name VARCHAR(100),
    order_name VARCHAR(100),
    family_name VARCHAR(100),
    species_name VARCHAR(255),
    common_name VARCHAR(255),
    description TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_family (family_name),
    INDEX idx_species (species_name)
);

CREATE TABLE IF NOT EXISTS postal (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    zip_code VARCHAR(10),
    city VARCHAR(100),
    state VARCHAR(50),
    county VARCHAR(100),
    latitude DECIMAL(10,6),
    longitude DECIMAL(10,6),
    INDEX idx_state (state),
    INDEX idx_zip (zip_code)
);

CREATE TABLE IF NOT EXISTS art_works (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    museum_name VARCHAR(255),
    title VARCHAR(500),
    artist VARCHAR(255),
    year_created VARCHAR(20),
    medium VARCHAR(255),
    collection VARCHAR(255),
    INDEX idx_museum (museum_name),
    INDEX idx_artist (artist)
);

CREATE TABLE IF NOT EXISTS publications (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    source_name VARCHAR(255),
    title VARCHAR(500),
    authors TEXT,
    doi VARCHAR(255),
    year_published VARCHAR(10),
    abstract_text TEXT,
    INDEX idx_source (source_name),
    INDEX idx_doi (doi)
);
SQL

echo ""
echo "[OK] All tables created in BrarnerScience:"
$MYSQL_CMD -e "USE BrarnerScience; SHOW TABLES;"
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo " [✓] MySQL setup complete"
echo "     User: root / \$\$Ironman1"
echo "     Database: BrarnerScience"
echo "     Next: bash install/populate-science-db.sh"
echo "═══════════════════════════════════════════════════════════════"
