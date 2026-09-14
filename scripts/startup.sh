#!/usr/bin/env bash
# startup.sh — start the National JDK Finance Engine (Main.java)
# GC: G1GC (aggressive), Heap: 512MB min / 4GB max

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# Build classpath (include DJL jars if present)
DJL_CP=$(find "$ROOT/jars/djl" -name "*.jar" 2>/dev/null | tr '\n' ':')
JPCAP_CP=$(find "$ROOT/jars/jpcap" -name "*.jar" 2>/dev/null | tr '\n' ':')
CP="$ROOT/out:$ROOT/jars/mysql/mysql-connector-j-9.7.0.jar:${DJL_CP}${JPCAP_CP}$ROOT/jars/lanterna-3.1.5.jar"

# Run as root if apache-root is under /var/www (requires root to create/write).
# If already root, just exec directly.
APACHE_DIR=$(grep -oP '(?<=<apache-root>)[^<]+' "$ROOT/configuration/nwe-config.xml" 2>/dev/null || echo "/var/www/html/nwe")

cd "$ROOT"

if [[ "$APACHE_DIR" == /var/www/* ]] && [[ "$(id -u)" -ne 0 ]]; then
    echo "[startup] Apache dir $APACHE_DIR requires root — restarting with sudo..."
    exec sudo java \
      -Dnwe.root="$ROOT" \
      -Xms512m \
      -Xmx4g \
      -XX:+UseG1GC \
      -XX:MaxGCPauseMillis=100 \
      -XX:G1HeapRegionSize=16m \
      -XX:+ParallelRefProcEnabled \
      -XX:+DisableExplicitGC \
      -cp "$CP" \
      Main
fi

exec java \
  -Dnwe.root="$ROOT" \
  -Xms512m \
  -Xmx4g \
  -XX:+UseG1GC \
  -XX:MaxGCPauseMillis=100 \
  -XX:G1HeapRegionSize=16m \
  -XX:+ParallelRefProcEnabled \
  -XX:+DisableExplicitGC \
  -cp "$CP" \
  Main
