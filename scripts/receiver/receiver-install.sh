#!/usr/bin/env bash
# receiver-install.sh — Install NWE Receiver-Only Mode
# MEARVK LLC — Max Rupplin
# Installs dependencies, generates TLS keystore, sets up MySQL DB or wallet dir.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "═══════════════════════════════════════════════════════"
echo "  NitroWebExpress™ — Receiver-Only Installer"
echo "  Contact: SSA Durham NC (proof of life)"
echo "═══════════════════════════════════════════════════════"

# 1. Ensure Java 21+
if ! command -v java &>/dev/null; then
    echo "[INSTALL] Java not found. Installing OpenJDK 21..."
    sudo apt-get update && sudo apt-get install -y openjdk-21-jdk
fi
echo "[INSTALL] Java: $(java -version 2>&1 | head -1)"

# 2. Generate TLS keystore if missing
KEYSTORE="$ROOT/psychiatry/secrets/receiver.keystore.jks"
if [ ! -f "$KEYSTORE" ]; then
    echo "[INSTALL] Generating RSA keystore for port 443..."
    mkdir -p "$(dirname "$KEYSTORE")"
    keytool -genkeypair -alias receiver -keyalg RSA -keysize 2048 \
        -validity 3650 -keystore "$KEYSTORE" -storepass changeit \
        -dname "CN=NWE Receiver, OU=MEARVK LLC, O=MEARVK, L=Durham, ST=NC, C=US" \
        -noprompt
    echo "[INSTALL] Keystore created: $KEYSTORE"
fi

# 3. Open port 443
echo "[INSTALL] Allowing port 443/tcp..."
sudo ufw allow 443/tcp 2>/dev/null || sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT

# 4. MySQL setup (optional — only if backend=mysql in config)
if grep -q '<backend>mysql</backend>' "$ROOT/configuration/receiver.only.xml" 2>/dev/null; then
    echo "[INSTALL] MySQL backend selected. Ensuring mysql-server is installed..."
    if ! command -v mysql &>/dev/null; then
        sudo apt-get install -y mysql-server
    fi
    echo "[INSTALL] Creating receiver database..."
    sudo mysql -e "CREATE DATABASE IF NOT EXISTS nwe_receiver;" 2>/dev/null || true
    sudo mysql -e "CREATE USER IF NOT EXISTS 'nwe'@'localhost' IDENTIFIED BY 'nwe_receiver_pass';" 2>/dev/null || true
    sudo mysql -e "GRANT ALL ON nwe_receiver.* TO 'nwe'@'localhost';" 2>/dev/null || true
    sudo mysql -e "FLUSH PRIVILEGES;" 2>/dev/null || true
    echo "[INSTALL] MySQL ready."
fi

# 5. Binary wallet directory
mkdir -p "$ROOT/data"

echo ""
echo "[INSTALL] Done. Run: bash scripts/receiver/receiver-compile.sh"
echo "          Then: sudo bash scripts/receiver/receiver-run.sh"
