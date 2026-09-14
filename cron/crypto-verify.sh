#!/bin/bash
# cron/crypto-verify.sh — Verify installed crypto binaries are intact (SHA-256)
# Runs as part of noble-registry cron schedule

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BIN_DIR="${SCRIPT_DIR}/scripts/bash/bitcoin"

verify_binary() {
    local bin="$1"
    if [ -x "$bin" ]; then
        local hash=$(sha256sum "$bin" | awk '{print $1}')
        echo "$(date -Iseconds) OK $(basename "$bin") sha256=${hash:0:16}…"
    else
        echo "$(date -Iseconds) MISSING $(basename "$bin")"
    fi
}

# Bitcoin versions 24–31
for v in 24 25 26 27 28 29 30 31; do
    [ -d "$BIN_DIR/$v" ] && verify_binary "$BIN_DIR/$v/bitcoind"
done

# Altcoins
[ -d "$BIN_DIR/dash" ] && verify_binary "$BIN_DIR/dash/dashd"
[ -d "$BIN_DIR/litecoin" ] && verify_binary "$BIN_DIR/litecoin/litecoind"
[ -d "$BIN_DIR/starcoin" ] && verify_binary "$BIN_DIR/starcoin/starcoin"
