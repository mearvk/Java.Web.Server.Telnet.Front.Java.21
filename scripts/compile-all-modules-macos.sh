#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# NitroWebExpress™ — Compile All Modules (macOS)
# Wrapper around compile-all-modules.sh that sets JAVA_HOME for macOS.
# Usage: bash scripts/compile-all-modules-macos.sh
# ═══════════════════════════════════════════════════════════════════════════════

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# Set JAVA_HOME for macOS
export JAVA_HOME="${JAVA_HOME:-$(/usr/libexec/java_home -v 21 2>/dev/null || echo /opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home)}"

if [ ! -d "$JAVA_HOME" ]; then
    echo "[FAIL] Java 21 not found. Install: brew install openjdk@21"
    exit 1
fi

echo "[*] JAVA_HOME=$JAVA_HOME"
export PATH="$JAVA_HOME/bin:$PATH"

# The main compile script is Linux/macOS compatible (: classpath separator)
exec bash "$ROOT/scripts/compile-all-modules.sh" "$@"
