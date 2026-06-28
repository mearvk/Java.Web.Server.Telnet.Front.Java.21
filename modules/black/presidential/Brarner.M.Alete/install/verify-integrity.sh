#!/usr/bin/env bash
# Brarner.M.Alete™ — Verify File Integrity
# Checks all webapp files against INTEGRITY.manifest
# Usage: bash install/verify-integrity.sh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BMA_ROOT="$(dirname "$SCRIPT_DIR")"
MANIFEST="$BMA_ROOT/INTEGRITY.manifest"

echo "═══════════════════════════════════════════════════════════════"
echo " Brarner.M.Alete™ — Integrity Verification"
echo "═══════════════════════════════════════════════════════════════"

if [ ! -f "$MANIFEST" ]; then
    echo "[!] INTEGRITY.manifest not found"; exit 1
fi

PASS=0; FAIL=0; MISSING=0; MODIFIED=0

while IFS= read -r line; do
    [[ "$line" =~ ^#.*$ ]] && continue
    [[ -z "$line" ]] && continue

    EXPECTED_SHA=$(echo "$line" | awk '{print $1}')
    FILEPATH=$(echo "$line" | awk '{print $3}')

    FULL_PATH="$BMA_ROOT/$FILEPATH"
    if [ ! -f "$FULL_PATH" ]; then
        echo "  [MISSING]  $FILEPATH"
        MISSING=$((MISSING + 1))
        continue
    fi

    ACTUAL_SHA=$(sha256sum "$FULL_PATH" | cut -d' ' -f1)
    if [ "$EXPECTED_SHA" = "$ACTUAL_SHA" ]; then
        PASS=$((PASS + 1))
    else
        echo "  [MODIFIED] $FILEPATH"
        echo "             expected: ${EXPECTED_SHA:0:16}..."
        echo "             actual:   ${ACTUAL_SHA:0:16}..."
        MODIFIED=$((MODIFIED + 1))
    fi
done < "$MANIFEST"

FAIL=$((MISSING + MODIFIED))
echo ""
echo "───────────────────────────────────────────────────────────────"
echo " Results: ${PASS} OK | ${MODIFIED} modified | ${MISSING} missing"
if [ "$FAIL" -eq 0 ]; then
    echo " Status: ✓ ALL FILES INTACT"
else
    echo " Status: ✗ INTEGRITY VIOLATION DETECTED"
fi
echo "───────────────────────────────────────────────────────────────"
exit $FAIL
