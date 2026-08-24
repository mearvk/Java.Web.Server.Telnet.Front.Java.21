#!/usr/bin/env bash
# NitroWebExpress — Build Fat JAR (macOS)
# Location-independent wrapper around build-jar.sh.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd -P)"

if [[ -z "${JAVA_HOME:-}" ]]; then
    if command -v /usr/libexec/java_home >/dev/null 2>&1; then
        JAVA_HOME="$(/usr/libexec/java_home -v 21 2>/dev/null || true)"
    fi
fi
if [[ -z "${JAVA_HOME:-}" || ! -d "$JAVA_HOME" ]]; then
    for candidate in \
        /opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home \
        /usr/local/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home; do
        if [[ -d "$candidate" ]]; then JAVA_HOME="$candidate"; break; fi
    done
fi

if [[ -z "${JAVA_HOME:-}" || ! -x "$JAVA_HOME/bin/javac" ]]; then
    echo "[FAIL] Java 21 not found. Install OpenJDK 21 (for example: brew install openjdk@21)." >&2
    exit 1
fi

export JAVA_HOME
export PATH="$JAVA_HOME/bin:$PATH"
export TMPDIR="${TMPDIR:-/tmp}"

echo "[*] JAVA_HOME=$JAVA_HOME"
exec bash "$ROOT/scripts/build-jar.sh" "$@"
