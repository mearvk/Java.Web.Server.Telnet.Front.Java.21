#!/usr/bin/env bash
# mysql.install.sh — install MySQL Server via apt-get

set -e

echo "[mysql.install] Updating package index..."
sudo apt-get update -y

echo "[mysql.install] Installing mysql-server..."
sudo apt-get install -y mysql-server

echo "[mysql.install] Enabling and starting MySQL service..."
sudo systemctl enable mysql
sudo systemctl start mysql

echo "[mysql.install] Done. MySQL is running."
