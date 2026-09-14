#!/usr/bin/env bash
# Ae6E66 — JDBC Connectivity Test (macOS)
# Usage: bash install/macos/test-jdbc.sh
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MOD_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
exec bash "$MOD_ROOT/install/test-jdbc.sh"
