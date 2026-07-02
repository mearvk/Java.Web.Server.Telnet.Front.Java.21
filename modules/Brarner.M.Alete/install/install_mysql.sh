#!/bin/bash
# Brarner.M.Alete™ — MySQL Install + Credential Setup
# Installs MySQL if needed, prompts for credentials, writes configuration/.my.cnf
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BMA_ROOT="$(dirname "$SCRIPT_DIR")"
CONFIG_DIR="$BMA_ROOT/configuration"
MY_CNF="$CONFIG_DIR/.my.cnf"

echo "═══════════════════════════════════════════════════════════════"
echo " Brarner.M.Alete™ — MySQL Setup"
echo "═══════════════════════════════════════════════════════════════"

# ─── Install MySQL if missing ───
if command -v mysql &>/dev/null; then
    echo "[*] MySQL client found: $(mysql --version | head -1)"
else
    echo "[*] MySQL not found — installing..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if command -v brew &>/dev/null; then
            brew install mysql
        else
            echo "[!] Install Homebrew first: https://brew.sh"; exit 1
        fi
    elif command -v apt-get &>/dev/null; then
        sudo apt-get update -qq && sudo apt-get install -y -qq mysql-server mysql-client
    elif command -v dnf &>/dev/null; then
        sudo dnf install -y mysql-server mysql
    elif command -v yum &>/dev/null; then
        sudo yum install -y mysql-server mysql
    else
        echo "[!] Install MySQL manually: https://dev.mysql.com/downloads/"; exit 1
    fi
fi

# ─── Start MySQL service ───
if [[ "$OSTYPE" == "darwin"* ]]; then
    brew services start mysql 2>/dev/null || true
else
    sudo systemctl enable mysql 2>/dev/null || sudo systemctl enable mysqld 2>/dev/null || true
    sudo systemctl start mysql 2>/dev/null || sudo systemctl start mysqld 2>/dev/null || true
fi

# ─── Prompt for credentials ───
echo ""
mkdir -p "$CONFIG_DIR"

if [ -f "$MY_CNF" ]; then
    echo "[*] Existing .my.cnf found at: $MY_CNF"
    read -rp "[?] Overwrite with new credentials? [y/N] " OVERWRITE
    if [[ ! "$OVERWRITE" =~ ^[Yy]$ ]]; then
        echo "[*] Keeping existing credentials."
        echo "═══════════════════════════════════════════════════════════════"
        exit 0
    fi
fi

echo "[*] Enter MySQL credentials for Brarner.M.Alete database access:"
echo ""
read -rp "    MySQL username [root]: " DB_USER
DB_USER="${DB_USER:-root}"

read -rsp "    MySQL password: " DB_PASS
echo ""

read -rp "    MySQL host [localhost]: " DB_HOST
DB_HOST="${DB_HOST:-localhost}"

read -rp "    MySQL port [3306]: " DB_PORT
DB_PORT="${DB_PORT:-3306}"

# ─── Write .my.cnf ───
cat > "$MY_CNF" <<EOF
[client]
user=${DB_USER}
password=${DB_PASS}
host=${DB_HOST}
port=${DB_PORT}
EOF

chmod 600 "$MY_CNF"

echo ""
echo "[✓] Credentials written to: $MY_CNF (mode 600)"

# ─── Verify connection ───
echo "[*] Testing connection..."
if mysql --defaults-extra-file="$MY_CNF" -e "SELECT 1;" &>/dev/null; then
    echo "[✓] MySQL connection OK"
else
    echo "[!] Connection failed — check credentials or MySQL service"
    echo "    File: $MY_CNF"
fi

echo "═══════════════════════════════════════════════════════════════"
