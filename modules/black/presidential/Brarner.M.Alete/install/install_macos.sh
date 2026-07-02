#!/bin/bash
# macOS-specific install script (uses Homebrew)
echo "============================================"
echo " MEARVK Project - macOS Install"
echo "============================================"
echo

if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "WARNING: This script is intended for macOS."
    echo "Use install.sh for generic Linux/macOS."
    exit 1
fi

if ! command -v brew &>/dev/null; then
    echo "Homebrew not found. Installing..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/../configuration"

echo "[1/4] Installing JARs..."
bash "$SCRIPT_DIR/install_jars.sh"
echo

echo "[2/4] Setting classpath..."
bash "$CONFIG_DIR/install_classpath.sh"
echo

echo "[3/4] MySQL via Homebrew..."
if brew list mysql &>/dev/null; then
    echo "  MySQL already installed."
    mysql --version
else
    echo "  Installing MySQL..."
    brew install mysql
fi
echo "  Starting MySQL service..."
brew services start mysql
echo

echo "[4/4] Checking ports..."
bash "$CONFIG_DIR/check_ports.sh"
echo

echo "============================================"
echo " macOS install complete."
echo "============================================"
