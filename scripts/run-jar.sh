#!/usr/bin/env bash
# run-jar.sh — Launch NitroWebExpress from the runnable JAR
# Ensures CWD is the project root so all relative configs resolve correctly.
# GC: G1GC, Heap: 512MB–4GB

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

exec java \
  -Dnwe.root="$ROOT" \
  -Xms512m \
  -Xmx4g \
  -XX:+UseG1GC \
  -XX:MaxGCPauseMillis=100 \
  -XX:G1HeapRegionSize=16m \
  -XX:+ParallelRefProcEnabled \
  -XX:+DisableExplicitGC \
  -jar nwe.jar
