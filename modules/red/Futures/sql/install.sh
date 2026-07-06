#!/bin/bash
# ============================================================
# MySQL Instance Setup Script
# Installer ID: MEARVK LLC - Max Rupplin
# D500 Democratic President
# ============================================================

echo "=== MySQL Instance Setup ==="
echo "Installer ID: MEARVK LLC - Max Rupplin"
echo ""

# Start MySQL if not running
sudo service mysql start

# Create database and user
sudo mysql -e "
CREATE DATABASE IF NOT EXISTS democratic_d500
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

CREATE USER IF NOT EXISTS 'mearvk_admin'@'localhost' IDENTIFIED BY 'CHANGE_ME_SECURE_PASSWORD';
GRANT ALL PRIVILEGES ON democratic_d500.* TO 'mearvk_admin'@'localhost';
FLUSH PRIVILEGES;
"

# Apply schema
sudo mysql democratic_d500 < /home/mearvk/IdeaProjects/Futures/sql/schema.sql

echo ""
echo "=== Schema applied ==="
echo "Database: democratic_d500"
echo "Tables: registrations, deregistrations, questions, answers,"
echo "        speculation_requests, speculation_results, tax_closures, defense_cases"
echo ""
echo "Installer ID: MEARVK LLC - Max Rupplin"
echo "=== Setup Complete ==="
