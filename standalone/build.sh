#!/usr/bin/env bash
# build.sh — Compiles and packages the NWE Module Installer standalone JAR
# Usage: bash standalone/build.sh
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE="$DIR/NWEModuleInstaller.java"
OUT="$DIR/out"
JAR="$DIR/nwe-module-installer.jar"

command -v javac >/dev/null 2>&1 || { echo "[FAIL] javac is required." >&2; exit 1; }
command -v jar >/dev/null 2>&1 || { echo "[FAIL] jar is required." >&2; exit 1; }
[[ -f "$SOURCE" ]] || { echo "[FAIL] Missing source: $SOURCE" >&2; exit 1; }

JAVA_MAJOR="$(javac -version 2>&1 | awk '{print $2}' | cut -d. -f1)"
[[ "$JAVA_MAJOR" =~ ^[0-9]+$ && "$JAVA_MAJOR" -ge 21 ]] || {
    echo "[FAIL] Java 21+ is required; detected javac $JAVA_MAJOR" >&2
    exit 1
}

cleanup() { rm -rf "$OUT"; }
trap cleanup EXIT

printf '%s\n' "=== Building NWE Module Installer (standalone) ==="
mkdir -p "$OUT"

echo "[1/3] Compiling..."
javac -d "$OUT" --release 21 "$SOURCE"

echo "[2/3] Creating manifest..."
printf 'Manifest-Version: 1.0\nMain-Class: NWEModuleInstaller\n' > "$OUT/MANIFEST.MF"

echo "[3/3] Packaging JAR..."
jar cfm "$JAR" "$OUT/MANIFEST.MF" -C "$OUT" .

[[ -s "$JAR" ]] || { echo "[FAIL] JAR was not created: $JAR" >&2; exit 1; }
echo "  Built: $JAR"
echo "  Run: java -jar $JAR"
echo "=== Done ==="
