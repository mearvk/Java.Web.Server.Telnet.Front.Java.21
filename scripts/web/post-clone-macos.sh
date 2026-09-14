#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# NitroWebExpress™ — Post-Clone Setup (macOS)
# Reads Tomcat version/path from configuration/nwe-config.xml <web-servers>
# Usage: bash scripts/web/post-clone-macos.sh
# ═══════════════════════════════════════════════════════════════════════════════
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

# macOS sed compatibility
if command -v gsed &>/dev/null; then
    SED="gsed"
else
    SED="sed"
    SED_INPLACE() { sed -i '' "$@"; }
fi
sed_inplace() {
    if command -v gsed &>/dev/null; then
        gsed -i "$@"
    else
        sed -i '' "$@"
    fi
}

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo " NitroWebExpress™ — Post-Clone Setup (macOS)"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# ── 1. Ensure Homebrew ────────────────────────────────────────────────────────
if ! command -v brew &>/dev/null; then
    echo "[FAIL] Homebrew required."
    echo "       Install: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    exit 1
fi
echo "[OK] Homebrew found"

# ── 2. Ensure Java 21 ────────────────────────────────────────────────────────
if ! java -version 2>&1 | grep -q "21\|22\|23"; then
    echo "[*] Installing Java 21..."
    brew install openjdk@21
    # Link for system java
    sudo ln -sfn "$(brew --prefix openjdk@21)/libexec/openjdk.jdk" /Library/Java/JavaVirtualMachines/openjdk-21.jdk 2>/dev/null || true
fi
export JAVA_HOME=$(/usr/libexec/java_home -v 21 2>/dev/null || echo "$(brew --prefix openjdk@21)/libexec/openjdk.jdk/Contents/Home")
echo "[OK] Java: $(java -version 2>&1 | head -1)"

# ── 3. Ensure MySQL ──────────────────────────────────────────────────────────
if ! command -v mysql &>/dev/null; then
    echo "[*] Installing MySQL..."
    brew install mysql
fi
brew services start mysql 2>/dev/null || true
sleep 2
echo "[OK] MySQL: $(mysql --version 2>/dev/null | head -1)"

# ── 4. Configure MySQL ───────────────────────────────────────────────────────
if [ -f "$PROJECT_ROOT/.nwe-credentials" ]; then
    source "$PROJECT_ROOT/.nwe-credentials"
    echo "[*] Loaded credentials from .nwe-credentials"
else
    echo "[*] Configuring MySQL root (default password)..."
    mysql -u root -e "SELECT 1;" 2>/dev/null || true
fi

# ── 5. Ensure Tomcat — read from nwe-config.xml ──────────────────────────────
NWE_CONFIG="$PROJECT_ROOT/configuration/nwe-config.xml"
TOMCAT_VERSION="11.0.2"
TOMCAT_HOME=""

if [ -f "$NWE_CONFIG" ]; then
    TOMCAT_VERSION=$($SED -n '/<tomcat>/,/<\/tomcat>/p' "$NWE_CONFIG" | grep -o '<version>[^<]*</version>' | $SED 's/<[^>]*>//g' 2>/dev/null || echo "11.0.2")
    TOMCAT_HOME=$($SED -n '/<tomcat>/,/<\/tomcat>/p' "$NWE_CONFIG" | grep -o '<install-dir>[^<]*</install-dir>' | $SED 's/<[^>]*>//g' 2>/dev/null)
fi

# On macOS, prefer Homebrew Tomcat
BREW_TOMCAT=""
if brew list tomcat &>/dev/null 2>&1; then
    BREW_TOMCAT="$(brew --prefix tomcat)/libexec"
fi

if [ -z "$TOMCAT_HOME" ] || [ ! -d "$TOMCAT_HOME/webapps" ]; then
    if [ -n "$BREW_TOMCAT" ] && [ -d "$BREW_TOMCAT/webapps" ]; then
        TOMCAT_HOME="$BREW_TOMCAT"
    elif [ -d "/opt/homebrew/opt/tomcat/libexec/webapps" ]; then
        TOMCAT_HOME="/opt/homebrew/opt/tomcat/libexec"
    elif [ -d "/usr/local/opt/tomcat/libexec/webapps" ]; then
        TOMCAT_HOME="/usr/local/opt/tomcat/libexec"
    fi
fi

if [ -z "$TOMCAT_HOME" ] || [ ! -d "$TOMCAT_HOME/webapps" ]; then
    echo "[*] Installing Tomcat via Homebrew..."
    brew install tomcat
    TOMCAT_HOME="$(brew --prefix tomcat)/libexec"
fi

echo "[OK] Tomcat ${TOMCAT_VERSION}: $TOMCAT_HOME"

# ── 6. Stamp Installer Tech ID ───────────────────────────────────────────────
INSTALLER_TECH_ID="${NWE_INSTALLER_TECH_ID:-$(hostname)-$(date +%Y%m%d-%H%M%S)}"
echo "[*] Installer Tech ID: $INSTALLER_TECH_ID"

if [ -f "$NWE_CONFIG" ]; then
    sed_inplace "/<tomcat>/,/<\/tomcat>/ s|<tech-id>[^<]*</tech-id>|<tech-id>${INSTALLER_TECH_ID}</tech-id>|" "$NWE_CONFIG"
    sed_inplace "/<apache>/,/<\/apache>/ s|<tech-id>[^<]*</tech-id>|<tech-id>${INSTALLER_TECH_ID}</tech-id>|" "$NWE_CONFIG"
    # Update install-dir to actual macOS path
    sed_inplace "/<tomcat>/,/<\/tomcat>/ s|<install-dir>[^<]*</install-dir>|<install-dir>${TOMCAT_HOME}</install-dir>|" "$NWE_CONFIG"
    echo "[OK] Tech ID and install-dir stamped in nwe-config.xml"
fi

# ── 7. Sync web-deploy-config.xml ────────────────────────────────────────────
DEPLOY_CONFIG="$PROJECT_ROOT/scripts/web/web-deploy-config.xml"
if [ -f "$DEPLOY_CONFIG" ]; then
    sed_inplace "s|<tomcat-home>[^<]*</tomcat-home>|<tomcat-home>${TOMCAT_HOME}</tomcat-home>|" "$DEPLOY_CONFIG"
    echo "[OK] web-deploy-config.xml synced"
fi

# ── 8. Make scripts executable ────────────────────────────────────────────────
find "$PROJECT_ROOT" -name "*.sh" -exec chmod +x {} \;
echo "[OK] Scripts: chmod +x applied"

# ── 9. Setup databases ───────────────────────────────────────────────────────
echo ""
echo "[*] Setting up module databases..."
if [ -f "$PROJECT_ROOT/scripts/web/setup-all-databases.sh" ]; then
    bash "$PROJECT_ROOT/scripts/web/setup-all-databases.sh" 2>/dev/null || echo "[WARN] Some databases may need manual setup"
fi

# ── 10. Deploy all ────────────────────────────────────────────────────────────
echo ""
bash "$SCRIPT_DIR/deploy-all-macos.sh"

# ── 11. Start Tomcat ──────────────────────────────────────────────────────────
brew services start tomcat 2>/dev/null || true

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo " Post-clone setup complete."
echo " Tomcat: $TOMCAT_HOME"
echo " All modules: http://localhost:8080/"
echo "═══════════════════════════════════════════════════════════════"
