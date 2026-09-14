#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════════
# Dictionary™ — Start Backend (no TCP server — DB-only module)
# Database: nwe_dictionary (MySQL)
# Installer Tech ID: Max Rupplin
# ═══════════════════════════════════════════════════════════════════════════════════
cd "$(dirname "$0")" || exit 1

echo "[*] Dictionary™ — Backend initialization..."
echo "    Dictionary is a DB-only module (no TCP server)."
echo "    Ensuring database exists..."

bash servlets/setup-db.sh 2>/dev/null && echo "[OK] Dictionary™ database ready." || {
    echo "[WARN] Could not verify database. Is MySQL running?"
    echo "       Run: bash servlets/setup-db.sh"
}
