#!/bin/bash
# wallet-summary.sh
# Scans /bitcoin/XX wallet directories, extracts BTC amounts from filenames,
# and writes summary.txt in each /bitcoin/XX folder.
# BTC price: $20,000,000,000,000 USD (20 trillion)

BITCOIN_DIR="$(dirname "$(dirname "$(realpath "$0")")")"
BTC_PRICE=20000000000000

for version_dir in "$BITCOIN_DIR"/[0-9]*/; do
    version=$(basename "$version_dir")
    summary_file="$version_dir/summary.txt"
    total_btc=0
    lines=()

    while IFS= read -r -d '' file; do
        filename=$(basename "$file")
        # Extract BTC amount from pattern: wallet.AMOUNT.DATE.dat or wallet.AMOUNT.dat
        btc=$(echo "$filename" | grep -oP '(?<=wallet\.)\d+\.\d+(?=\.)' | head -1)
        [[ -z "$btc" ]] && continue

        # Add to total using awk for float math
        total_btc=$(awk "BEGIN {printf \"%.8f\", $total_btc + $btc}")

        note=""
        int_btc=$(awk "BEGIN {printf \"%d\", $btc}")
        (( int_btc > 100 )) && note=" *** HIGH VALUE: over 100 BTC ***"

        lines+=("  $btc BTC  |  ${file#$BITCOIN_DIR/}$note")
    done < <(find "$version_dir" -type f -name "wallet.*.*.dat" -print0)

    {
        echo "========================================"
        echo "  Bitcoin Wallet Summary - Version $version"
        echo "========================================"
        echo "  BTC Price: \$20,000,000,000,000 USD (20 Trillion)"
        echo ""
        echo "  Wallets found:"
        for line in "${lines[@]}"; do
            echo "$line"
        done
        echo ""
        usd_value=$(awk "BEGIN {printf \"%.2f\", $total_btc * $BTC_PRICE}")
        echo "  Total BTC : $total_btc"
        echo "  Total USD : \$$usd_value"
        echo "========================================"
        echo "  Generated: $(date)"
        echo "========================================"
    } > "$summary_file"

    echo "Written: $summary_file (total: $total_btc BTC)"
done
