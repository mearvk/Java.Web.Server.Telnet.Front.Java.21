#!/bin/bash
# scripts/bash/bitcoin/install-crypto-binaries.sh
# Downloads and installs Bitcoin Core (v24–31), Dashcoin, Starcoin, and Litecoin.
# Bitcoin Core installation is fail-closed on missing or invalid SHA-256 checksums.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALL_BASE="${SCRIPT_DIR}"
TARGET="${1:-all}"
BTC_BASE="https://bitcoincore.org/bin/bitcoin-core-"
BTC_VERSIONS=(24.2 25.2 26.2 27.1 28.1 29.0 30.0 31.0)
DASH_VERSION="21.1.1"
DASH_URL="https://github.com/dashpay/dash/releases/download/v${DASH_VERSION}/dashcore-${DASH_VERSION}-x86_64-linux-gnu.tar.gz"
LITECOIN_VERSION="0.21.3"
LITECOIN_URL="https://download.litecoin.org/litecoin-${LITECOIN_VERSION}/linux/litecoin-${LITECOIN_VERSION}-x86_64-linux-gnu.tar.gz"
STARCOIN_VERSION="1.13.7"
STARCOIN_URL="https://github.com/starcoinorg/starcoin/releases/download/v${STARCOIN_VERSION}/starcoin-ubuntu-v${STARCOIN_VERSION}.zip"

verify_bitcoin_checksum() {
    local tarball="$1"
    local sums="$2"
    local expected
    expected="$(awk -v f="$tarball" '$2 == f || $2 == "*" f {print $1; exit}' "$sums")"
    if [[ ! "$expected" =~ ^[0-9a-fA-F]{64}$ ]]; then
        echo "FAIL: no trusted SHA-256 entry for ${tarball}" >&2
        return 1
    fi
    printf '%s  %s\n' "$expected" "$tarball" | sha256sum -c -
}

install_bitcoin() {
    local VER="$1"
    local MAJOR="${VER%%.*}"
    local DIR="${INSTALL_BASE}/${MAJOR}"
    local TARBALL="bitcoin-${VER}-x86_64-linux-gnu.tar.gz"
    local URL="${BTC_BASE}${VER}/${TARBALL}"
    local CHECKSUM_URL="${BTC_BASE}${VER}/SHA256SUMS"
    local WORK="$(mktemp -d -t bitcoin-core-${MAJOR}-XXXXXX)"
    trap 'rm -rf "$WORK"' RETURN

    mkdir -p "$DIR"
    echo "-- : [crypto] Installing Bitcoin Core v${VER} to ${DIR}"
    cd "$WORK"
    curl -# -fL "$URL" -o "$TARBALL"
    curl -# -fL "$CHECKSUM_URL" -o SHA256SUMS
    echo "    Verifying SHA-256 checksum..."
    verify_bitcoin_checksum "$TARBALL" SHA256SUMS
    echo "    ✓ checksum verified"

    tar -xzf "$TARBALL"
    install -m 0755 "bitcoin-${VER}/bin/bitcoind" "$DIR/bitcoind"
    install -m 0755 "bitcoin-${VER}/bin/bitcoin-cli" "$DIR/bitcoin-cli"
    sudo ln -sf "$DIR/bitcoind" /usr/local/bin/bitcoind
    sudo ln -sf "$DIR/bitcoin-cli" /usr/local/bin/bitcoin-cli
    echo "-- : [crypto] Bitcoin Core v${VER} verified and installed"
}

install_dash() {
    local DIR="${INSTALL_BASE}/dash"
    mkdir -p "$DIR"
    cd /tmp
    curl -# -fL "$DASH_URL" -o "dashcore-${DASH_VERSION}-x86_64-linux-gnu.tar.gz"
    tar -xzf "dashcore-${DASH_VERSION}-x86_64-linux-gnu.tar.gz"
    install -m 0755 "dashcore-${DASH_VERSION}/bin/dashd" "$DIR/dashd"
    install -m 0755 "dashcore-${DASH_VERSION}/bin/dash-cli" "$DIR/dash-cli"
    sudo ln -sf "$DIR/dashd" /usr/local/bin/dashd
    sudo ln -sf "$DIR/dash-cli" /usr/local/bin/dash-cli
    rm -rf "dashcore-${DASH_VERSION}"* 
}

install_litecoin() {
    local DIR="${INSTALL_BASE}/litecoin"
    mkdir -p "$DIR"
    cd /tmp
    curl -# -fL "$LITECOIN_URL" -o "litecoin-${LITECOIN_VERSION}-x86_64-linux-gnu.tar.gz"
    tar -xzf "litecoin-${LITECOIN_VERSION}-x86_64-linux-gnu.tar.gz"
    install -m 0755 "litecoin-${LITECOIN_VERSION}/bin/litecoind" "$DIR/litecoind"
    install -m 0755 "litecoin-${LITECOIN_VERSION}/bin/litecoin-cli" "$DIR/litecoin-cli"
    sudo ln -sf "$DIR/litecoind" /usr/local/bin/litecoind
    sudo ln -sf "$DIR/litecoin-cli" /usr/local/bin/litecoin-cli
    rm -rf "litecoin-${LITECOIN_VERSION}"*
}

install_starcoin() {
    local DIR="${INSTALL_BASE}/starcoin"
    mkdir -p "$DIR"
    cd /tmp
    curl -# -fL "$STARCOIN_URL" -o "starcoin-ubuntu-v${STARCOIN_VERSION}.zip"
    unzip -qo "starcoin-ubuntu-v${STARCOIN_VERSION}.zip" -d starcoin-extract
    install -m 0755 starcoin-extract/starcoin "$DIR/starcoin" 2>/dev/null || install -m 0755 starcoin-extract/*/starcoin "$DIR/starcoin"
    sudo ln -sf "$DIR/starcoin" /usr/local/bin/starcoin
    rm -rf starcoin-extract "starcoin-ubuntu-v${STARCOIN_VERSION}.zip"
}

case "$TARGET" in
    btc) for ver in "${BTC_VERSIONS[@]}"; do install_bitcoin "$ver"; done ;;
    dash) install_dash ;;
    ltc) install_litecoin ;;
    star) install_starcoin ;;
    all)
        for ver in "${BTC_VERSIONS[@]}"; do install_bitcoin "$ver"; done
        install_dash
        install_litecoin
        install_starcoin
        ;;
    *) echo "Usage: $0 [btc|dash|star|ltc|all]"; exit 1 ;;
esac

echo "-- : [crypto] Installation complete. Binaries in ${INSTALL_BASE}/"
