#!/usr/bin/env bash
# wallet-summary.sh
# Scans bitcoin/<version>/wallets for wallet.*.dat files and writes metadata.
# This script never treats wallet-file size as a Bitcoin balance.
# Optional valuation: BTC_PRICE_USD=<price> ./wallet-summary.sh
set -euo pipefail

BITCOIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BTC_PRICE_USD="${BTC_PRICE_USD:-}"

for version_dir in "$BITCOIN_DIR"/[0-9]*/; do
    [[ -d "$version_dir" ]] || continue
    version="$(basename "$version_dir")"
    summary_file="$version_dir/summary.txt"

    {
        echo "========================================"
        echo "  Bitcoin Wallet Metadata - Version $version"
        echo "========================================"
        if [[ -n "$BTC_PRICE_USD" ]]; then
            echo "  Valuation price: $$BTC_PRICE_USD USD/BTC (operator supplied)"
        else
            echo "  Valuation price: NOT SET"
        fi
        echo ""
        echo "  Wallet files:"
        found=0
        while IFS= read -r -d '' file; do
            found=1
            filename="$(basename "$file")"
            size="$(stat -c '%s' "$file")"
            digest="$(sha256sum "$file" | awk '{print $1}')"
            echo "  $filename | bytes=$size | sha256=$digest"
        done < <(find "$version_dir/wallets" -type f -name 'wallet.*.dat' -print0 2>/dev/null | sort -z)

        [[ "$found" -eq 1 ]] || echo "  (none found)"
        echo ""
        echo "  IMPORTANT: file size and filename are not wallet balances."
        echo "  Use Bitcoin Core RPC (getbalances/getwalletinfo) for authoritative balances."
        echo "  Generated: $(date --iso-8601=seconds)"
        echo "========================================"
    } > "$summary_file"

    echo "Written: $summary_file"
done
