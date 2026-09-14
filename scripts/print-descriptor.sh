#!/bin/bash
# scripts/print-descriptor.sh — Print script title and description from print-method.xml
# Source this from any NWE script: source "$(dirname "$0")/print-descriptor.sh" 2>/dev/null || true
# Or call directly: bash scripts/print-descriptor.sh <script-filename>
#
# Reads <script-descriptors> from configuration/print-method.xml and prints
# the Title Case name and purpose for the calling script.

_NWE_PRINT_DESCRIPTOR() {
    local SCRIPT_NAME="${1:-$(basename "$0")}"
    local CONFIG

    # Find config relative to project root
    if [ -n "${PROJECT_ROOT:-}" ]; then
        CONFIG="$PROJECT_ROOT/configuration/print-method.xml"
    elif [ -n "${ROOT:-}" ]; then
        CONFIG="$ROOT/configuration/print-method.xml"
    else
        # Try to detect from script location
        local SCRIPT_DIR
        SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[1]:-${BASH_SOURCE[0]}}")" 2>/dev/null && pwd)"
        # Walk up looking for configuration/
        local CHECK="$SCRIPT_DIR"
        for _ in 1 2 3 4; do
            if [ -f "$CHECK/configuration/print-method.xml" ]; then
                CONFIG="$CHECK/configuration/print-method.xml"
                break
            fi
            CHECK="$(dirname "$CHECK")"
        done
    fi

    if [ -z "$CONFIG" ] || [ ! -f "$CONFIG" ]; then
        return 0  # Silently skip if config not found
    fi

    # Extract title and description for this script
    local TITLE DESC
    TITLE=$(grep -A1 "file=\"$SCRIPT_NAME\"" "$CONFIG" 2>/dev/null | head -1 | grep -oP '(?<=title=")[^"]+')
    DESC=$(sed -n "/file=\"$SCRIPT_NAME\"/,/<\/script>/p" "$CONFIG" 2>/dev/null | sed '1d;$d' | sed 's/^[[:space:]]*//' | head -1)

    if [ -n "$TITLE" ]; then
        echo ""
        echo "  ┌─ $TITLE"
        if [ -n "$DESC" ]; then
            echo "  │  $DESC"
        fi
        echo "  └─────────────────────────────────────────────────────────────"
        echo ""
    fi
}

# If sourced, auto-print for the calling script
# If run directly with an argument, print for that script name
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    _NWE_PRINT_DESCRIPTOR "${1:-}"
else
    _NWE_PRINT_DESCRIPTOR "$(basename "$0")"
fi
