#!/bin/bash
# btc24-query.sh
# Starts bitcoind from Desktop/Bitcoin/24, loads wallet, queries balance,
# and writes SUMMARY.txt to bitcoin/24/

BITCOIN_DIR="$HOME/Desktop/Bitcoin/24"
SUMMARY_DIR="$(dirname "$(dirname "$(realpath "$0")")")/24"
SUMMARY_FILE="$SUMMARY_DIR/SUMMARY.txt"
CLI="$BITCOIN_DIR/bitcoin-cli"
BITCOIND="$BITCOIN_DIR/bitcoind"
RPC_PORT="${BITCOIN_RPC_PORT:-2222}"
RPC_ARGS="-regtest -rpcport=$RPC_PORT"
WALLET="Xenu Emperor"
BTC_PRICE_USD="${BTC_PRICE_USD:-}"

echo "[1/5] Starting bitcoind..."
bash "$BITCOIN_DIR/start.sh"
sleep 3

echo "[2/5] Waiting for RPC to be ready..."
for i in {1..15}; do
    $CLI $RPC_ARGS getblockchaininfo &>/dev/null && break
    sleep 2
done

echo "[3/5] Loading wallet..."
LOAD_RESULT=$(bash "$BITCOIN_DIR/loadwallet.sh" 2>&1)
echo "      $LOAD_RESULT"

echo "[4/5] Querying balance..."
BALANCE=$($CLI $RPC_ARGS -rpcwallet="$WALLET" getbalance 2>&1)
WALLET_INFO=$($CLI $RPC_ARGS -rpcwallet="$WALLET" getwalletinfo 2>&1)

echo "[5/5] Writing $SUMMARY_FILE..."
if [[ -n "$BTC_PRICE_USD" ]]; then
    USD_VALUE=$(awk "BEGIN {printf \"%.2f\", ${BALANCE:-0} * $BTC_PRICE_USD}" 2>/dev/null || echo "N/A")
else
    USD_VALUE="NOT SET"
fi

{
    echo "========================================"
    echo "  Bitcoin Node Summary - Version 24"
    echo "========================================"
    echo "  Wallet     : $WALLET"
    echo "  Balance    : $BALANCE BTC"
    echo "  USD Value  : $USD_VALUE"
    [[ -n "$BTC_PRICE_USD" ]] && echo "  Price      : \$BTC_PRICE_USD/BTC (operator supplied)"
    echo ""
    echo "  Wallet Info:"
    echo "$WALLET_INFO" | sed 's/^/    /'
    echo ""
    echo "  Generated  : $(date)"
    echo "========================================"
} > "$SUMMARY_FILE"

echo "Done. Summary written to $SUMMARY_FILE"
cat "$SUMMARY_FILE"
