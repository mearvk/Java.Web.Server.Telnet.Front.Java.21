#!/bin/bash
# Brarner.M.Alete™ — Populate ALL Tables (macOS)
# Delegates to the main Linux scripts (same bash/mysql).
# Usage: bash install/macos/populate-all.sh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BMA_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
exec bash "$BMA_ROOT/install/populate-all.sh"
