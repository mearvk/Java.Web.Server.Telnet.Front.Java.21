#!/bin/bash
# NCSU™ — Check Database (macOS)
set -e
echo "[*] Checking nwe_ncsu database..."
mysql -u root -e "USE nwe_ncsu; SELECT COUNT(*) AS tables_count FROM information_schema.tables WHERE table_schema='nwe_ncsu';"
echo "[OK] Database check complete."
