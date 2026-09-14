#!/usr/bin/env bash
# Futures — Local Connectivity Test (macOS)
# Usage: bash install/macos/test-local.sh [port]
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MOD_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
exec bash "$MOD_ROOT/install/test-local.sh" "$@"
