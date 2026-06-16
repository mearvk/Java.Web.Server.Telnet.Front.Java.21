#!/usr/bin/env bash
# Startup.sh — start the National JDK Finance Engine (Main.java)
# GC: G1GC (aggressive), Heap: 512MB min / 4GB max

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# ── Pre-flight: XML fallback wellness check ────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
bash "$SCRIPT_DIR/N21.XML.Wellness.Check.sh"

# Run as root if apache-root is under /var/www (requires root to create/write).
# If already root, just exec directly.
APACHE_DIR=$(grep -oP '(?<=<apache-root>)[^<]+' "$ROOT/configuration/nwe-config.xml" 2>/dev/null || echo "/var/www/html/nwe")

if [[ "$APACHE_DIR" == /var/www/* ]] && [[ "$(id -u)" -ne 0 ]]; then
    echo "[startup] Apache dir $APACHE_DIR requires root — restarting with sudo..."
    exec sudo java \
      -Xms512m \
      -Xmx4g \
      -XX:+UseG1GC \
      -XX:MaxGCPauseMillis=100 \
      -XX:G1HeapRegionSize=16m \
      -XX:+ParallelRefProcEnabled \
      -XX:+DisableExplicitGC \
      -cp "$ROOT/out" \
      Main
fi

exec java \
  -Xms512m \
  -Xmx4g \
  -XX:+UseG1GC \
  -XX:MaxGCPauseMillis=100 \
  -XX:G1HeapRegionSize=16m \
  -XX:+ParallelRefProcEnabled \
  -XX:+DisableExplicitGC \
  -cp "$ROOT/out" \
  Main
