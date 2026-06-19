#!/usr/bin/env bash
# receiver-compile.sh — Compile NWE Receiver-Only sources
# MEARVK LLC — Max Rupplin
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ROOT="$(cd "$ROOT/.." && pwd)"
SRC="$ROOT/src/receiver"
OUT="$ROOT/out/receiver"
MYSQL_JAR="$ROOT/jars/mysql/mysql-connector-j-9.7.0.jar"

echo "═══════════════════════════════════════════════════════"
echo "  NitroWebExpress™ — Receiver Compile"
echo "═══════════════════════════════════════════════════════"

mkdir -p "$OUT"

CP="$SRC"
[ -f "$MYSQL_JAR" ] && CP="$CP:$MYSQL_JAR"

echo "[COMPILE] Compiling receiver sources..."
javac -d "$OUT" -cp "$CP" "$SRC"/ReceiverConfig.java "$SRC"/ReceiverStorage.java "$SRC"/ReceiverMain.java

echo "[COMPILE] Success. Classes in: $OUT"
