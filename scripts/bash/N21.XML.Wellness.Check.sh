#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
# N21 XML Fallback Wellness Check
# Scans all database/fallback/**/N21.xml files for well-formedness.
# Repairs malformed files by consolidating into a single <N21> root.
# Run at startup before the JVM process.
# ─────────────────────────────────────────────────────────────────────────────

FALLBACK_DIR="database/fallback"
FIXED=0
ERRORS=0
CHECKED=0

if [ ! -d "$FALLBACK_DIR" ]; then
    echo "[XML-Check] No fallback directory found. Nothing to check."
    exit 0
fi

for XML in "$FALLBACK_DIR"/*/N21.xml; do
    [ -f "$XML" ] || continue
    CHECKED=$((CHECKED + 1))

    # Quick well-formedness test via python (no external deps)
    if python3 -c "import xml.etree.ElementTree as ET; ET.parse('$XML')" 2>/dev/null; then
        continue
    fi

    ERRORS=$((ERRORS + 1))
    echo "[XML-Check] MALFORMED: $XML — repairing..."

    # Repair: strip all </N21> and re-wrap in a single root
    python3 -c "
import sys
f = sys.argv[1]
with open(f, 'r') as fh:
    content = fh.read()

# Remove all root open/close tags
content = content.replace('<N21>', '').replace('</N21>', '')

# Strip blank lines at start/end
content = content.strip()

# Re-wrap
with open(f, 'w') as fh:
    fh.write('<N21>\n' + content + '\n</N21>\n')
" "$XML"

    # Verify repair
    if python3 -c "import xml.etree.ElementTree as ET; ET.parse('$XML')" 2>/dev/null; then
        echo "[XML-Check] REPAIRED: $XML"
        FIXED=$((FIXED + 1))
    else
        echo "[XML-Check] REPAIR FAILED: $XML — manual intervention needed."
    fi
done

echo "[XML-Check] Done. Checked=$CHECKED  Errors=$ERRORS  Fixed=$FIXED"
exit 0
