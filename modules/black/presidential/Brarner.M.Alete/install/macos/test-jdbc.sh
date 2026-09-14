#!/bin/bash
# Brarner.M.Alete™ — Test JDBC Connectivity (macOS)
# Same as Linux — delegates to main test-jdbc.sh
# Usage: bash install/macos/test-jdbc.sh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BMA_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
exec bash "$BMA_ROOT/install/test-jdbc.sh"
