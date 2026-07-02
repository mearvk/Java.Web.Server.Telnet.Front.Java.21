#!/usr/bin/env bash
# Ae6E66 — Database Population Check (macOS)
# Usage: bash install/macos/check-db.sh
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MOD_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
exec bash "$MOD_ROOT/install/check-db.sh"
