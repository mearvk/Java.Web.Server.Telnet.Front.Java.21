#!/bin/bash
# Brarner.M.Alete™ — Populate ALL Tables (Linux/macOS)
# Runs all population scripts in sequence.
# Usage: bash install/populate-all.sh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BMA_ROOT="$(dirname "$SCRIPT_DIR")"

echo "═══════════════════════════════════════════════════════════════"
echo " Brarner.M.Alete™ — Populate All Tables"
echo "═══════════════════════════════════════════════════════════════"
echo ""

bash "$SCRIPT_DIR/populate-science-db.sh"
echo ""
bash "$SCRIPT_DIR/populate-postal.sh"
echo ""
bash "$SCRIPT_DIR/populate-art.sh"
echo ""
bash "$SCRIPT_DIR/populate-publications.sh"
echo ""
bash "$SCRIPT_DIR/populate-ssa.sh"

echo ""
echo "[*] Populating legal data..."
bash "$BMA_ROOT/data/legal/download-legal-data.sh"
echo ""
echo "[*] Processing legal data into safe formats..."
bash "$BMA_ROOT/data/legal/unzip-and-consume.sh"
echo ""
echo "[*] Loading legal data into MySQL..."
bash "$SCRIPT_DIR/populate-legal.sh"

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo " [✓] All tables populated"
echo "     animalia, species, postal, art_works, publications, ssa_offices, legal"
echo "═══════════════════════════════════════════════════════════════"
