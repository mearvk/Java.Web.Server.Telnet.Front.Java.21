#!/usr/bin/env bash
# build.sh — Compiles and packages the NWE Module Installer standalone JAR
# Usage: bash standalone/build.sh

set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
OUT="$DIR/out"
JAR="$DIR/nwe-module-installer.jar"

echo "=== Building NWE Module Installer (standalone) ==="

mkdir -p "$OUT"

echo "[1/3] Compiling..."
javac -d "$OUT" --release 21 "$DIR/NWEModuleInstaller.java"

echo "[2/3] Creating manifest..."
echo "Main-Class: NWEModuleInstaller" > "$OUT/MANIFEST.MF"

echo "[3/3] Packaging JAR..."
jar cfm "$JAR" "$OUT/MANIFEST.MF" -C "$OUT" .

rm -rf "$OUT"

echo ""
echo "  ✔  Built: $JAR"
echo "  Run:  java -jar $JAR"
echo ""
echo "=== Done ==="
