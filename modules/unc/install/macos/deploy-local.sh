#!/bin/bash
# UNC Chapel Hill™ — Deploy Local (macOS)
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MOD_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
bash "$MOD_ROOT/servlets/deploy-local.sh" "$@"
