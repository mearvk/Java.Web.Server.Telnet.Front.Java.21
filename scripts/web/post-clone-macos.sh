#!/bin/bash
# NitroWebExpress™ — Post-Clone Setup (macOS)
# Usage: bash scripts/web/post-clone-macos.sh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

echo "═══════════════════════════════════════════════════════════════"
echo " NitroWebExpress™ — Post-Clone Setup (macOS)"
echo "═══════════════════════════════════════════════════════════════"

# 1. Ensure Homebrew
if ! command -v brew &>/dev/null; then
    echo "[!] Homebrew required. Install: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    exit 1
fi

# 2. Ensure Java 21
if ! java -version 2>&1 | grep -q "21\|22\|23"; then
    echo "[*] Installing Java 21..."
    brew install openjdk@21
fi
echo "[OK] Java: $(java -version 2>&1 | head -1)"

# 3. Ensure MySQL
if ! command -v mysql &>/dev/null; then
    echo "[*] Installing MySQL..."
    brew install mysql && brew services start mysql
fi
echo "[OK] MySQL: $(mysql --version)"

# 4. Configure MySQL root
mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH caching_sha2_password BY '\$\$Ironman1'; FLUSH PRIVILEGES;" 2>/dev/null || true

# 5. Ensure Tomcat
if ! brew list tomcat &>/dev/null; then
    echo "[*] Installing Tomcat..."
    brew install tomcat
fi
echo "[OK] Tomcat installed"

# 6. Make scripts executable
find "$PROJECT_ROOT" -name "*.sh" -exec chmod +x {} \;

# 7. Deploy all
bash "$SCRIPT_DIR/deploy-all-macos.sh"

# 8. Start
brew services start tomcat
echo ""
echo "[OK] All modules deployed. http://localhost:8080/"
echo "═══════════════════════════════════════════════════════════════"
