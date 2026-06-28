#!/usr/bin/env bash
# Brarner.M.Alete™ — Regenerate Integrity Manifest
# Usage: bash install/generate-integrity.sh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BMA_ROOT="$(dirname "$SCRIPT_DIR")"
MANIFEST="$BMA_ROOT/INTEGRITY.manifest"

echo "═══════════════════════════════════════════════════════════════"
echo " Brarner.M.Alete™ — Generate Integrity Manifest"
echo "═══════════════════════════════════════════════════════════════"

cat > "$MANIFEST" <<HEADER
# Brarner.M.Alete™ — File Integrity Manifest
# Generated: $(date +%Y-%m-%d)
# Version: 1.5.1
# Format: SHA-256  MD5  Path
#
# Verify: bash install/verify-integrity.sh
# Regenerate: bash install/generate-integrity.sh
#
HEADER

cd "$BMA_ROOT"
COUNT=0
find servlets/servlet/src/main/webapp -type f | sort | while read -r f; do
    SHA=$(sha256sum "$f" | cut -d' ' -f1)
    MD5=$(md5sum "$f" | cut -d' ' -f1)
    echo "$SHA  $MD5  $f" >> "$MANIFEST"
done

COUNT=$(grep -c -v '^#' "$MANIFEST" | grep -c '' || wc -l < <(grep -v '^#' "$MANIFEST" | grep -v '^$'))
echo "[✓] Manifest written: $MANIFEST"
echo "    Files: $(grep -v '^#' "$MANIFEST" | grep -v '^$' | wc -l)"
echo "═══════════════════════════════════════════════════════════════"
