#!/usr/bin/env bash
# build-jar.sh — Build a runnable fat JAR for NitroWebExpress quick deployment
# Output: nwe.jar in project root. Launch via: bash scripts/run-jar.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/source"
OUT="$ROOT/out"
JAR_OUT="$ROOT/nwe.jar"
MYSQL_JAR="$ROOT/jars/mysql/mysql-connector-j-9.7.0.jar"
LANTERNA_JAR="$ROOT/jars/lanterna-3.1.5.jar"
DJL_DIR="$ROOT/jars/djl"

echo "=== NitroWebExpress — JAR Builder ==="
echo "ROOT: $ROOT"

# ── 1. Compile ────────────────────────────────────────────────────────────────
echo "[1/3] Compiling sources..."
mkdir -p "$OUT"
DJL_CP=$(find "$DJL_DIR" -name "*.jar" 2>/dev/null | tr '\n' ':')
CP="$OUT:$MYSQL_JAR:${DJL_CP}$LANTERNA_JAR"

find "$SRC" -name "*.java" > /tmp/nwe-sources.txt
javac --release 21 -cp "$CP" -sourcepath "$SRC" -d "$OUT" @/tmp/nwe-sources.txt 2>&1
rm -f /tmp/nwe-sources.txt
echo "      Compiled."

# ── 2. Assemble fat JAR ──────────────────────────────────────────────────────
echo "[2/3] Assembling fat JAR..."
STAGING=$(mktemp -d)
trap "rm -rf $STAGING" EXIT

# Copy application classes
cp -a "$OUT"/. "$STAGING/"

# Extract dependency JARs into staging (fat jar approach)
for dep in "$MYSQL_JAR" "$LANTERNA_JAR"; do
    [ -f "$dep" ] && unzip -qo "$dep" -d "$STAGING" -x 'META-INF/MANIFEST.MF' 'META-INF/*.SF' 'META-INF/*.RSA' 'META-INF/*.DSA'
done

# DJL jars (excluding the huge native blob — that stays external)
for dep in $(find "$DJL_DIR" -name "*.jar" ! -name "*native*" 2>/dev/null); do
    unzip -qo "$dep" -d "$STAGING" -x 'META-INF/MANIFEST.MF' 'META-INF/*.SF' 'META-INF/*.RSA' 'META-INF/*.DSA'
done

# Write manifest
mkdir -p "$STAGING/META-INF"
cat > "$STAGING/META-INF/MANIFEST.MF" <<EOF
Manifest-Version: 1.0
Main-Class: Main
Class-Path: jars/djl/pytorch-native-cpu-2.5.1-linux-x86_64.jar
EOF

# ── 3. Create JAR ────────────────────────────────────────────────────────────
echo "[3/3] Creating $JAR_OUT..."
jar cfm "$JAR_OUT" "$STAGING/META-INF/MANIFEST.MF" -C "$STAGING" .
echo "      Done. Size: $(du -h "$JAR_OUT" | cut -f1)"
echo ""
echo "=== Run with: bash scripts/run-jar.sh ==="
