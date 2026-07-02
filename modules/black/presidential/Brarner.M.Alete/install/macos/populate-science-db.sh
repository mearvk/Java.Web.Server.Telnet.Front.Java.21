#!/bin/bash
# Brarner.M.Alete™ — Populate Science Database (macOS)
# Same as Linux populate script — macOS uses same bash/mysql tools.
# Usage: bash install/macos/populate-science-db.sh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BMA_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

# Delegate to the main populate script
exec bash "$BMA_ROOT/install/populate-science-db.sh"
