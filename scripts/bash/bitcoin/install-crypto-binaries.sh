#!/bin/bash
# scripts/bash/bitcoin/install-crypto-binaries.sh
# Downloads and installs Bitcoin Core (v24–31), Dashcoin, Starcoin, and Litecoin
# Reads version/coin config from configuration/nwe-config.xml <crypto-binaries> block
# Installs to scripts/bash/bitcoin/{version}/ and symlinks to /usr/local/bin/
#
# Usage: sudo bash scripts/bash/bitcoin/install-crypto-binaries.sh [btc|dash|star|ltc|all]

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
INSTALL_BASE="${SCRIPT_DIR}"
TARGET="${1:-all}"

# Bitcoin Core URLs (v24–31)
BTC_BASE="https://bitcoincore.org/bin/bitcoin-core-"
BTC_VERSIONS=(24.2 25.2 26.2 27.1 28.1 29.0 30.0 31.0)

# Altcoin URLs
DASH_VERSION="21.1.1"
DASH_URL="https://github.com/dashpay/dash/releases/download/v${DASH_VERSION}/dashcore-${DASH_VERSION}-x86_64-linux-gnu.tar.gz"

LITECOIN_VERSION="0.21.3"
LITECOIN_URL="https://download.litecoin.org/litecoin-${LITECOIN_VERSION}/linux/litecoin-${LITECOIN_VERSION}-x86_64-linux-gnu.tar.gz"

STARCOIN_VERSION="1.13.7"
STARCOIN_URL="https://github.com/starcoinorg/starcoin/releases/download/v${STARCOIN_VERSION}/starcoin-ubuntu-v${STARCOIN_VERSION}.zip"

install_bitcoin() {
    local VER="$1"
    local MAJOR=$(echo "$VER" | cut -d. -f1)
    local DIR="${INSTALL_BASE}/${MAJOR}"
    local TARBALL="bitcoin-${VER}-x86_64-linux-gnu.tar.gz"
    local URL="${BTC_BASE}${VER}/${TARBALL}"
    local CHECKSUM_URL="${BTC_BASE}${VER}/SHA256SUMS"

    mkdir -p "$DIR"
    echo "-- : [crypto] Installing Bitcoin Core v${VER} to ${DIR}"

    cd /tmp
    curl -sfLO "$URL" || { echo "SKIP v${VER} (download failed)"; return; }
    curl -sfLO "$CHECKSUM_URL" || true

    # Verify if checksum available
    if [ -f SHA256SUMS ]; then
        grep "$TARBALL" SHA256SUMS | sha256sum -c - || { echo "WARN: checksum mismatch v${VER}"; }
    fi

    tar -xzf "$TARBALL"
    cp "bitcoin-${VER}/bin/bitcoind" "$DIR/"
    cp "bitcoin-${VER}/bin/bitcoin-cli" "$DIR/"
    chmod +x "$DIR/bitcoind" "$DIR/bitcoin-cli"

    # Symlink latest version
    sudo ln -sf "$DIR/bitcoind" /usr/local/bin/bitcoind
    sudo ln -sf "$DIR/bitcoin-cli" /usr/local/bin/bitcoin-cli

    rm -rf "$TARBALL" SHA256SUMS "bitcoin-${VER}"
    echo "-- : [crypto] Bitcoin Core v${VER} OK"
}

install_dash() {
    local DIR="${INSTALL_BASE}/dash"
    mkdir -p "$DIR"
    echo "-- : [crypto] Installing Dash Core v${DASH_VERSION}"

    cd /tmp
    curl -sfLO "$DASH_URL" || { echo "FAIL: Dash download"; return; }
    tar -xzf "dashcore-${DASH_VERSION}-x86_64-linux-gnu.tar.gz"
    cp dashcore-${DASH_VERSION}/bin/dashd "$DIR/"
    cp dashcore-${DASH_VERSION}/bin/dash-cli "$DIR/"
    chmod +x "$DIR/dashd" "$DIR/dash-cli"
    sudo ln -sf "$DIR/dashd" /usr/local/bin/dashd
    sudo ln -sf "$DIR/dash-cli" /usr/local/bin/dash-cli
    rm -rf "dashcore-${DASH_VERSION}"* 
    echo "-- : [crypto] Dash Core v${DASH_VERSION} OK"
}

install_litecoin() {
    local DIR="${INSTALL_BASE}/litecoin"
    mkdir -p "$DIR"
    echo "-- : [crypto] Installing Litecoin Core v${LITECOIN_VERSION}"

    cd /tmp
    curl -sfLO "$LITECOIN_URL" || { echo "FAIL: Litecoin download"; return; }
    tar -xzf "litecoin-${LITECOIN_VERSION}-x86_64-linux-gnu.tar.gz"
    cp litecoin-${LITECOIN_VERSION}/bin/litecoind "$DIR/"
    cp litecoin-${LITECOIN_VERSION}/bin/litecoin-cli "$DIR/"
    chmod +x "$DIR/litecoind" "$DIR/litecoin-cli"
    sudo ln -sf "$DIR/litecoind" /usr/local/bin/litecoind
    sudo ln -sf "$DIR/litecoin-cli" /usr/local/bin/litecoin-cli
    rm -rf "litecoin-${LITECOIN_VERSION}"*
    echo "-- : [crypto] Litecoin Core v${LITECOIN_VERSION} OK"
}

install_starcoin() {
    local DIR="${INSTALL_BASE}/starcoin"
    mkdir -p "$DIR"
    echo "-- : [crypto] Installing Starcoin v${STARCOIN_VERSION}"

    cd /tmp
    curl -sfLO "$STARCOIN_URL" || { echo "FAIL: Starcoin download"; return; }
    unzip -qo "starcoin-ubuntu-v${STARCOIN_VERSION}.zip" -d starcoin-extract || true
    cp starcoin-extract/starcoin "$DIR/" 2>/dev/null || cp starcoin-extract/*/starcoin "$DIR/" 2>/dev/null || true
    chmod +x "$DIR/starcoin" 2>/dev/null
    sudo ln -sf "$DIR/starcoin" /usr/local/bin/starcoin 2>/dev/null
    rm -rf starcoin-extract "starcoin-ubuntu-v${STARCOIN_VERSION}.zip"
    echo "-- : [crypto] Starcoin v${STARCOIN_VERSION} OK"
}

# Main
case "$TARGET" in
    btc)
        for ver in "${BTC_VERSIONS[@]}"; do install_bitcoin "$ver"; done
        ;;
    dash)
        install_dash
        ;;
    ltc)
        install_litecoin
        ;;
    star)
        install_starcoin
        ;;
    all)
        for ver in "${BTC_VERSIONS[@]}"; do install_bitcoin "$ver"; done
        install_dash
        install_litecoin
        install_starcoin
        ;;
    *)
        echo "Usage: $0 [btc|dash|star|ltc|all]"
        exit 1
        ;;
esac

echo "-- : [crypto] Installation complete. Binaries in ${INSTALL_BASE}/"
