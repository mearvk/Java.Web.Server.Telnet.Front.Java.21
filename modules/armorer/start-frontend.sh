#!/bin/bash
# Armorer™ — Start Frontend (deploy webapp)
cd "$(dirname "$0")" || exit 1
bash servlets/deploy-local.sh "$@"
echo "[OK] Armorer™ frontend started."
