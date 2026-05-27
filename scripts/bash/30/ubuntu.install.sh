#!/bin/bash
set -e

# Configuration
VERSION="30.2"
URL="https://bitcoincore.org"
TARBALL="bitcoin-$VERSION-x86_64-linux-gnu.tar.gz"
CHECKSUMS="SHA256SUMS"

# 1. Download the binaries and checksums
echo "Downloading Bitcoin Core v$VERSION..."
wget -q "$URL"
wget -q "https://bitcoincore.org"
wget -q "https://bitcoincore.org.asc"

# 2. Verify the download
echo "Verifying checksums..."
sha256sum --ignore-missing --check "$CHECKSUMS"

# 3. Extract and install
echo "Installing bitcoind and bitcoin-cli to /usr/local/bin..."
tar -xzf "$TARBALL"
sudo install -m 0755 -o root -g root -t /usr/local/bin "bitcoin-$VERSION/bin/bitcoind" "bitcoin-$VERSION/bin/bitcoin-cli"

# 4. Clean up
echo "Cleaning up installation files..."
rm -rf "$TARBALL" "$CHECKSUMS" "$CHECKSUMS.asc" "bitcoin-$VERSION"

echo "Installation complete!"
echo "Verify version by running: bitcoind --version"
