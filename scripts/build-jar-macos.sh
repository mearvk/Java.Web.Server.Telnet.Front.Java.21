#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# NitroWebExpress™ — Build Fat JAR (macOS)
# Wrapper around build-jar.sh that handles macOS specifics.
# Usage: bash scripts/build-jar-macos.sh
# ═══════════════════════════════════════════════════════════════════════════════

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# Set JAVA_HOME for macOS
export JAVA_HOME="${JAVA_HOME:-$(/usr/libexec/java_home -v 21 2>/dev/null || echo /opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home)}"

if [ ! -d "$JAVA_HOME" ]; then
    echo "[FAIL] Java 21 not found. Install: brew install openjdk@21"
    exit 1
fi

export PATH="$JAVA_HOME/bin:$PATH"

# macOS mktemp needs a template with X's
export TMPDIR="${TMPDIR:-/tmp}"

# The main build script is Linux/macOS compatible
exec bash "$ROOT/scripts/build-jar.sh" "$@"
