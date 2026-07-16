#!/bin/bash
# UNC Chapel Hill™ — Check Database (macOS)
set -e
echo "[*] Checking nwe_unc database..."
mysql -u root -e "USE nwe_unc; SELECT COUNT(*) AS tables_count FROM information_schema.tables WHERE table_schema='nwe_unc';"
echo "[OK] Database check complete."
