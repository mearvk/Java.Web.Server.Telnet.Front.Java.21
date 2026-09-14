cat << 'EOF' > install_bitcoin.sh
#!/bin/bash
set -e

# Configuration
VERSION="28.1"
TARBALL="bitcoin-${VERSION}-x86_64-linux-gnu.tar.gz"
URL="https://bitcoincore.org{VERSION}/${TARBALL}"
CHECKSUM_URL="https://bitcoincore.org{VERSION}/SHA256SUMS"

# 1. Install prerequisites
sudo apt-get update
sudo apt-get install -y wget tar gnupg curl

# 2. Download Bitcoin Core binaries and checksums
cd /tmp
wget -qO "$TARBALL" "$URL"
wget -qO SHA256SUMS "$CHECKSUM_URL"

# 3. Verify the checksums
grep "$TARBALL" SHA256SUMS | sha256sum -c -

# 4. Extract and Install
tar -xzf "$TARBALL"
sudo install -m 0755 -o root -g root -t /usr/local/bin "bitcoin-${VERSION}/bin/bitcoind"
sudo install -m 0755 -o root -g root -t /usr/local/bin "bitcoin-${VERSION}/bin/bitcoin-cli"

# 5. Clean up
rm -rf "$TARBALL" SHA256SUMS "bitcoin-${VERSION}"

echo "Bitcoin Core version $VERSION installed successfully!"
echo "You can now run: bitcoind -version"
EOF

# Make it executable and run it
chmod +x install_bitcoin.sh
./install_bitcoin.sh
