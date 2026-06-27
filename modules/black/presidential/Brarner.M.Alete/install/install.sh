#!/usr/bin/env bash
# Brarner.M.Alete™ — Install Script (Linux/macOS)
# Deploys the BMA servlet website to a local Tomcat or Jetty container.
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BMA_ROOT="$(dirname "$SCRIPT_DIR")"
WEBAPP_SRC="$BMA_ROOT/servlets/servlet/src/main/webapp"
DEPLOY_DIR="${BMA_DEPLOY_DIR:-/opt/bma}"
TOMCAT_WEBAPPS="${CATALINA_HOME:-/opt/tomcat}/webapps"

echo "═══════════════════════════════════════════════════════════════"
echo " Brarner.M.Alete™ — Website Installer"
echo " MEARVK LLC — NC Socialist-College Block"
echo "═══════════════════════════════════════════════════════════════"

# Detect OS
OS="$(uname -s)"
case "$OS" in
    Linux*)  PLATFORM="linux" ;;
    Darwin*) PLATFORM="macos" ;;
    *)       echo "Unsupported OS: $OS"; exit 1 ;;
esac
echo "[*] Platform: $PLATFORM"

# Check Java 21+
if ! command -v java &>/dev/null; then
    echo "[!] Java not found. Install JDK 21+ first."
    exit 1
fi
JAVA_VER=$(java -version 2>&1 | head -1 | grep -oP '"\K[0-9]+' | head -1)
if [ "$JAVA_VER" -lt 21 ] 2>/dev/null; then
    echo "[!] Java 21+ required (found: $JAVA_VER)"
    exit 1
fi
echo "[*] Java $JAVA_VER detected"

# Create deploy directory
echo "[*] Creating deploy directory: $DEPLOY_DIR"
sudo mkdir -p "$DEPLOY_DIR"
sudo mkdir -p "$DEPLOY_DIR/webapp"
sudo mkdir -p "$DEPLOY_DIR/lib"
sudo mkdir -p "$DEPLOY_DIR/logs"

# Copy webapp files
echo "[*] Copying webapp files..."
sudo cp -r "$WEBAPP_SRC/"* "$DEPLOY_DIR/webapp/"

# Copy JARs if present
if [ -d "$BMA_ROOT/lib" ]; then
    echo "[*] Copying library JARs..."
    sudo cp "$BMA_ROOT/lib/"*.jar "$DEPLOY_DIR/lib/" 2>/dev/null || true
fi

# Deploy to Tomcat if available
if [ -d "$TOMCAT_WEBAPPS" ]; then
    echo "[*] Tomcat detected at: $TOMCAT_WEBAPPS"
    sudo mkdir -p "$TOMCAT_WEBAPPS/bma"
    sudo cp -r "$WEBAPP_SRC/"* "$TOMCAT_WEBAPPS/bma/"
    if [ -d "$BMA_ROOT/lib" ]; then
        sudo mkdir -p "$TOMCAT_WEBAPPS/bma/WEB-INF/lib"
        sudo cp "$BMA_ROOT/lib/"*.jar "$TOMCAT_WEBAPPS/bma/WEB-INF/lib/" 2>/dev/null || true
    fi
    echo "[*] Deployed to Tomcat: $TOMCAT_WEBAPPS/bma"
else
    echo "[*] Tomcat not found at $TOMCAT_WEBAPPS — skipping auto-deploy"
    echo "    Set CATALINA_HOME to deploy automatically."
fi

# Set permissions
sudo chmod -R 755 "$DEPLOY_DIR"

echo ""
echo "[✓] Installation complete."
echo "    Deploy dir: $DEPLOY_DIR"
echo "    Run download-jars.sh to fetch required dependencies."
echo "═══════════════════════════════════════════════════════════════"
