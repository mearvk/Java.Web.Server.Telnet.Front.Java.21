#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# Defined™ — Check MySQL Database (macOS)
# In memory of Steve Jobs. Think Different.
# NitroWebExpress™ — MEARVK LLC
# ═══════════════════════════════════════════════════════════════════════════════
set -e

echo ""
echo "╔═══════════════════════════════════════════════════════════════════════╗"
echo "║  Defined™ — Check Database (macOS)                                    ║"
echo "║  In memory of Steve Jobs.                                             ║"
echo "╚═══════════════════════════════════════════════════════════════════════╝"
echo ""

if ! command -v mysql &>/dev/null; then
    echo "  [!] MySQL client not found."
    echo "      Install: brew install mysql"
    exit 1
fi

echo "  [*] Checking database 'defined_dark_gray'..."
if mysql -u root -e "SELECT 1" -D defined_dark_gray &>/dev/null; then
    echo "  [OK] Database 'defined_dark_gray' exists and is accessible."
else
    echo "  [--] Database not found or not accessible."
    echo "       Run: bash sql/install.sh"
fi
echo ""
