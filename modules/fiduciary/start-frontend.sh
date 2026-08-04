#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════════
# FiduciaryServices™ — Start Frontend (deploy webapp)
# Installer Tech ID: Max Rupplin
# ═══════════════════════════════════════════════════════════════════════════════════
cd "$(dirname "$0")" || exit 1
bash servlets/deploy-local.sh "$@"
echo "[OK] FiduciaryServices™ frontend started."
