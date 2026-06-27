#!/usr/bin/env bash
# Brarner.M.Alete™ — Install Script (Linux/macOS)
# Deploys the BMA Java Enterprise servlet website.
# Auto-installs Tomcat 11 if not present (BMA requires Jakarta Servlet 6.1).
# Checks Apache2 alias config and reverse DNS before remote deploy.
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BMA_ROOT="$(dirname "$SCRIPT_DIR")"
WEBAPP_SRC="$BMA_ROOT/servlets/servlet/src/main/webapp"
DEPLOY_DIR="${BMA_DEPLOY_DIR:-/opt/bma}"
TOMCAT_HOME="${CATALINA_HOME:-/opt/tomcat}"
TOMCAT_WEBAPPS="$TOMCAT_HOME/webapps"
TOMCAT_VERSION="11.0.2"
TOMCAT_URL="https://archive.apache.org/dist/tomcat/tomcat-11/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz"

# Remote server settings
REMOTE_HOST="${BMA_REMOTE_HOST:-45.32.31.139}"
REMOTE_DOMAIN="lauradei.us"
REMOTE_PATH="/var/www/html/brarner.m.alete"
REMOTE_USER="${BMA_REMOTE_USER:-root}"
SSH_OPTS="-o ConnectTimeout=10 -o BatchMode=yes -o ServerAliveInterval=15 -o ServerAliveCountMax=3"

echo "═══════════════════════════════════════════════════════════════"
echo " Brarner.M.Alete™ — Website Installer (Java Enterprise)"
echo " MEARVK LLC — NC Socialist-College Block"
echo "═══════════════════════════════════════════════════════════════"

# ─── Pre-flight checks ───

# Check webapp source
if [ ! -d "$WEBAPP_SRC" ]; then
    echo "[!] Webapp source not found: $WEBAPP_SRC"
    echo "    Build the project first."
    exit 1
fi

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
JAVA_VER=$(java -version 2>&1 | head -1 | grep -oP '"\K[0-9]+' | head -1 || java -version 2>&1 | head -1 | sed 's/.*"\([0-9]*\).*/\1/')
if [ "$JAVA_VER" -lt 21 ] 2>/dev/null; then
    echo "[!] Java 21+ required (found: $JAVA_VER)"
    exit 1
fi
echo "[*] Java $JAVA_VER detected"

# ─── Install Tomcat locally if not present (BMA = Java Enterprise) ───

if [ -d "$TOMCAT_HOME" ] && [ -f "$TOMCAT_HOME/bin/catalina.sh" ]; then
    echo "[*] Tomcat already installed at: $TOMCAT_HOME"
else
    INSTALL_TOMCAT="y"
    if [ -t 0 ]; then
        read -rp "[?] Tomcat not found. Install Tomcat ${TOMCAT_VERSION} for BMA servlets? [Y/n] " INSTALL_TOMCAT
        INSTALL_TOMCAT="${INSTALL_TOMCAT:-y}"
    fi

    if [[ "$INSTALL_TOMCAT" =~ ^[Yy]$ ]]; then
        echo "[*] Installing Tomcat ${TOMCAT_VERSION} (Jakarta Servlet 6.1 runtime)..."
        cd /tmp
        curl -sfLO "$TOMCAT_URL"
        sudo mkdir -p "$TOMCAT_HOME"
        sudo tar -xzf "apache-tomcat-${TOMCAT_VERSION}.tar.gz" -C "$TOMCAT_HOME" --strip-components=1
        rm -f "apache-tomcat-${TOMCAT_VERSION}.tar.gz"

        # Create service user on Linux
        if [ "$PLATFORM" = "linux" ]; then
            id tomcat &>/dev/null || sudo useradd -r -M -d "$TOMCAT_HOME" -s /bin/false tomcat
            sudo chown -R tomcat:tomcat "$TOMCAT_HOME"

            # Systemd service
            sudo tee /etc/systemd/system/tomcat.service > /dev/null <<EOF
[Unit]
Description=Apache Tomcat 11
After=network.target

[Service]
Type=forking
User=tomcat
Group=tomcat
Environment=JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))
Environment=CATALINA_HOME=${TOMCAT_HOME}
Environment=CATALINA_PID=${TOMCAT_HOME}/temp/tomcat.pid
ExecStart=${TOMCAT_HOME}/bin/startup.sh
ExecStop=${TOMCAT_HOME}/bin/shutdown.sh
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
            sudo systemctl daemon-reload
            sudo systemctl enable tomcat
            sudo systemctl start tomcat
        else
            # macOS — just make executable
            chmod +x "$TOMCAT_HOME"/bin/*.sh
            "$TOMCAT_HOME/bin/startup.sh"
        fi
        echo "[*] Tomcat ${TOMCAT_VERSION} installed and started"
    else
        echo "[*] Skipping Tomcat — BMA servlet features will not be available"
    fi
fi

TOMCAT_WEBAPPS="$TOMCAT_HOME/webapps"

# ─── Local deploy ───

echo "[*] Creating deploy directory: $DEPLOY_DIR"
sudo mkdir -p "$DEPLOY_DIR"/{webapp,lib,logs}

echo "[*] Copying webapp files..."
sudo cp -r "$WEBAPP_SRC/"* "$DEPLOY_DIR/webapp/"

if [ -d "$BMA_ROOT/lib" ]; then
    echo "[*] Copying library JARs..."
    sudo cp "$BMA_ROOT/lib/"*.jar "$DEPLOY_DIR/lib/" 2>/dev/null || true
fi

# Deploy to Tomcat webapps
if [ -d "$TOMCAT_WEBAPPS" ]; then
    echo "[*] Deploying to Tomcat: $TOMCAT_WEBAPPS/bma"
    sudo mkdir -p "$TOMCAT_WEBAPPS/bma/WEB-INF/lib"
    sudo cp -r "$WEBAPP_SRC/"* "$TOMCAT_WEBAPPS/bma/"
    if [ -d "$BMA_ROOT/lib" ]; then
        sudo cp "$BMA_ROOT/lib/"*.jar "$TOMCAT_WEBAPPS/bma/WEB-INF/lib/" 2>/dev/null || true
    fi
    echo "[*] Deployed to Tomcat context: /bma"
fi

sudo chmod -R 755 "$DEPLOY_DIR"

echo ""
echo "[✓] Local installation complete."
echo "    Deploy dir: $DEPLOY_DIR"
echo "    Tomcat: $TOMCAT_WEBAPPS/bma"

# ─── Remote deploy (with pre-flight checks) ───

echo ""
echo "───────────────────────────────────────────────────────────────"

CONFIRM="n"
if [ -t 0 ]; then
    read -rp " Deploy to remote Linux server at https://${REMOTE_DOMAIN}/brarner.m.alete? [Y/n] " CONFIRM
    CONFIRM="${CONFIRM:-Y}"
fi

if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
    # Pre-flight: Reverse DNS check
    echo "[*] Checking reverse DNS for ${REMOTE_HOST}..."
    RDNS=$(dig +short -x "$REMOTE_HOST" 2>/dev/null | head -1 || echo "")
    if [ -n "$RDNS" ]; then
        echo "[*] PTR: ${REMOTE_HOST} → ${RDNS}"
        if ! echo "$RDNS" | grep -qi "lauradei"; then
            echo "[!] WARNING: PTR does not match ${REMOTE_DOMAIN}"
        fi
    else
        echo "[!] WARNING: No reverse DNS for ${REMOTE_HOST}"
    fi

    # Pre-flight: SSH access
    echo "[*] Verifying SSH access..."
    if ! ssh $SSH_OPTS "$REMOTE_USER@$REMOTE_HOST" "echo OK" 2>/dev/null; then
        echo "[!] Cannot SSH to ${REMOTE_HOST}. Skipping remote deploy."
        echo "    Try: ssh-copy-id ${REMOTE_USER}@${REMOTE_HOST}"
    else
        # Check existing alias config
        ALIAS_EXISTS=$(ssh $SSH_OPTS "$REMOTE_USER@$REMOTE_HOST" "
            [ -f /etc/apache2/conf-available/brarner-m-alete.conf ] || \
            [ -f /etc/apache2/conf-enabled/brarner-m-alete.conf ] || \
            [ -f /etc/httpd/conf.d/brarner-m-alete.conf ] && echo EXISTS || echo NONE
        " 2>/dev/null)
        if [ "$ALIAS_EXISTS" = "EXISTS" ]; then
            echo "[*] Apache alias config already exists on remote"
        fi

        # Deploy files
        echo "[*] Deploying to ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_PATH}..."
        ssh $SSH_OPTS "$REMOTE_USER@$REMOTE_HOST" "mkdir -p $REMOTE_PATH/WEB-INF/lib"
        scp -o ConnectTimeout=10 -o BatchMode=yes -r "$WEBAPP_SRC/"* "$REMOTE_USER@$REMOTE_HOST:$REMOTE_PATH/"
        if [ -d "$BMA_ROOT/lib" ]; then
            scp -o ConnectTimeout=10 -o BatchMode=yes "$BMA_ROOT/lib/"*.jar "$REMOTE_USER@$REMOTE_HOST:$REMOTE_PATH/WEB-INF/lib/" 2>/dev/null || true
        fi
        ssh $SSH_OPTS "$REMOTE_USER@$REMOTE_HOST" "chmod -R 755 $REMOTE_PATH"
        echo "[✓] Remote deploy complete: https://${REMOTE_DOMAIN}/brarner.m.alete"
        echo "    For full SSL/Tomcat setup run: bash install/deploy-remote-linux.sh"
    fi
else
    echo "[*] Skipped remote deploy."
    echo "    Full remote setup: bash install/deploy-remote-linux.sh"
fi

echo "═══════════════════════════════════════════════════════════════"
