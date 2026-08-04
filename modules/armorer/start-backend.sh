#!/bin/bash
# Armorer™ — Start Backend
cd "$(dirname "$0")" || exit 1
echo "[*] Armorer™ — Starting backend..."
bash servlets/setup-db.sh 2>/dev/null || echo "[WARN] DB setup skipped."
echo "[OK] Armorer™ backend ready."
