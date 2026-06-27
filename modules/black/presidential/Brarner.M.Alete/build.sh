#!/bin/bash
# Build script for Brarner.M.Alete™ — Linux/macOS
# Compiles servlets and produces a deployable WAR file.
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BMA_ROOT="$SCRIPT_DIR"
SERVLET_SRC="$BMA_ROOT/servlets/servlet/src/main/java"
WEBAPP_SRC="$BMA_ROOT/servlets/servlet/src/main/webapp"
OUT_DIR="$BMA_ROOT/build/classes"
WAR_NAME="brarner.m.alete.war"
LIB_DIR="$BMA_ROOT/lib"

echo "═══════════════════════════════════════════════════════════════"
echo " Brarner.M.Alete™ — Build"
echo "═══════════════════════════════════════════════════════════════"

# Check JARs exist
if [ ! -d "$LIB_DIR" ] || [ -z "$(ls "$LIB_DIR"/*.jar 2>/dev/null)" ]; then
    echo "[!] No JARs in lib/. Run: bash install/download-jars.sh"
    exit 1
fi

mkdir -p "$OUT_DIR"

# Find servlet sources
find "$SERVLET_SRC" -name "*.java" > "$BMA_ROOT/build/sources.txt"
SRC_COUNT=$(wc -l < "$BMA_ROOT/build/sources.txt")
echo "[*] Compiling ${SRC_COUNT} Java sources..."

# Compile against Jakarta Servlet API
javac -d "$OUT_DIR" -cp "$LIB_DIR/*" @"$BMA_ROOT/build/sources.txt"
echo "[*] Compilation OK"

# Build WAR
echo "[*] Packaging ${WAR_NAME}..."
WAR_STAGING="$BMA_ROOT/build/war"
rm -rf "$WAR_STAGING"
mkdir -p "$WAR_STAGING/WEB-INF/classes" "$WAR_STAGING/WEB-INF/lib"

# Copy webapp resources (xhtml, css, images, config, WEB-INF/web.xml)
cp -r "$WEBAPP_SRC/"* "$WAR_STAGING/"

# Copy compiled classes
cp -r "$OUT_DIR/"* "$WAR_STAGING/WEB-INF/classes/"

# Copy runtime JARs (MySQL connector — servlet-api is provided by container)
cp "$LIB_DIR/mysql-connector-j-"*.jar "$WAR_STAGING/WEB-INF/lib/" 2>/dev/null || true

# Create WAR
cd "$WAR_STAGING"
jar cf "$BMA_ROOT/$WAR_NAME" .
cd "$BMA_ROOT"

echo "[✓] Built: $WAR_NAME ($(du -h "$WAR_NAME" | cut -f1))"
echo "═══════════════════════════════════════════════════════════════"
