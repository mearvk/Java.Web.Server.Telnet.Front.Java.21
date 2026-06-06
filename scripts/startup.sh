#!/usr/bin/env bash
# startup.sh — start the National JDK Finance Engine (Main.java)
# GC: G1GC (aggressive), Heap: 512MB min / 4GB max

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

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
