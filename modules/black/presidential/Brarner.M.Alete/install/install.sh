#!/bin/bash
echo "============================================"
echo " MEARVK Project - Central Install Script"
echo "============================================"
echo

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/../configuration"

echo "[1/4] Installing JARs..."
bash "$SCRIPT_DIR/install_jars.sh"
echo

echo "[2/4] Setting classpath..."
bash "$CONFIG_DIR/install_classpath.sh"
echo

echo "[3/4] Installing MySQL..."
bash "$SCRIPT_DIR/install_mysql.sh"
echo

echo "[4/4] Checking ports..."
bash "$CONFIG_DIR/check_ports.sh"
echo

echo "============================================"
echo " Install complete."
echo "============================================"
