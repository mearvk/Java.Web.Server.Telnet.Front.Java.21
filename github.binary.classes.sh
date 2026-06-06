#!/usr/bin/env bash
# github.binary.classes.sh
# Moves all .class files from /source to the corresponding /out directory.

ROOT="$(cd "$(dirname "$0")" && pwd)"
SRC="$ROOT/source"
OUT="$ROOT/out"

find "$SRC" -name "*.class" | while read -r class; do
    rel="${class#$SRC/}"
    dest="$OUT/$rel"
    mkdir -p "$(dirname "$dest")"
    mv "$class" "$dest"
done

echo "Done."
