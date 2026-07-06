#!/usr/bin/env bash
# compile.check.sh — Compile all source Java files and report errors.
# Uses the project's jar dependencies and --release 25.
set -e

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/source"
OUT="$ROOT/out"

if ! command -v javac &> /dev/null; then
    echo "Error: javac must be installed." >&2
    exit 1
fi

mkdir -p "$OUT"

DJL_CP=$(find "$ROOT/jars/djl" -name "*.jar" 2>/dev/null | tr '\n' ':')
CP="$OUT:$ROOT/jars/mysql/mysql-connector-j-9.7.0.jar:${DJL_CP}$ROOT/jars/lanterna-3.1.5.jar"

find "$SRC" -name "*.java" > /tmp/nwe-compile-check.txt
javac -d "$OUT" --release 25 -cp "$CP" -sourcepath "$SRC" @/tmp/nwe-compile-check.txt
rm -f /tmp/nwe-compile-check.txt
echo "Compilation successful."
