#!/usr/bin/env bash
# Brarner.M.Alete™ — Install Script (Linux/macOS)
# Builds and deploys the BMA Jakarta EE servlet website.
# Installs Tomcat 11 if not present (requires Jakarta Servlet 6.0+).
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BMA_ROOT="$(dirname "$SCRIPT_DIR")"
WEBAPP_SRC="$BMA_ROOT/servlets/servlet/src/main/webapp"
WAR_FILE="$BMA_ROOT/brarner.m.alete.war"
TOMCAT_HOME="${CATALINA_HOME:-/opt/tomcat}"
TOMCAT_CONTEXT="brarner.m.alete"
TOMCAT_VERSION="11.0.2"
TOMCAT_URL="https://archive.apache.org/dist/tomcat/tomcat-11/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz"

# Remote settings
REMOTE_HOST="${BMA_REMOTE_HOST:-45.32.31.139}"
REMOTE_DOMAIN="lauradei.us"
REMOTE_USER="${BMA_REMOTE_USER:-root}"
SSH_OPTS="-o ConnectTimeout=10 -o BatchMode=yes -o ServerAliveInterval=15 -o ServerAliveCountMax=3"

echo "═══════════════════════════════════════════════════════════════"
echo " Brarner.M.Alete™ — Website Installer"
echo " MEARVK LLC — NC Socialist-College Block"
echo "═══════════════════════════════════════════════════════════════"

# ─── Pre-flight ───

if [ ! -d "$WEBAPP_SRC" ]; then
    echo "[!] Webapp source not found: $WEBAPP_SRC"
    exit 1
fi

OS="$(uname -s)"
case "$OS" in
    Linux*)  PLATFORM="linux" ;;
    Darwin*) PLATFORM="macos" ;;
    *)       echo "[!] Unsupported OS: $OS"; exit 1 ;;
esac
echo "[*] Platform: $PLATFORM"

if ! command -v java &>/dev/null; then
    echo "[!] Java not found. Install JDK 21+."
    exit 1
fi
JAVA_VER=$(java -version 2>&1 | head -1 | grep -oP '"\K[0-9]+' 2>/dev/null || java -version 2>&1 | head -1 | sed 's/.*"\([0-9]*\).*/\1/')
if [ "$JAVA_VER" -lt 21 ] 2>/dev/null; then
    echo "[!] Java 21+ required (found: $JAVA_VER)"
    exit 1
fi
echo "[*] Java $JAVA_VER"

# ─── MySQL credentials (writes .my.cnf) ───
MY_CNF="$BMA_ROOT/configuration/.my.cnf"
if [ ! -f "$MY_CNF" ]; then
    echo ""
    echo "[*] MySQL credentials needed for Brarner.M.Alete database:"
    read -rp "    MySQL username [root]: " DB_USER
    DB_USER="${DB_USER:-root}"
    read -rsp "    MySQL password: " DB_PASS
    echo ""
    read -rp "    MySQL host [localhost]: " DB_HOST
    DB_HOST="${DB_HOST:-localhost}"
    read -rp "    MySQL port [3306]: " DB_PORT
    DB_PORT="${DB_PORT:-3306}"
    mkdir -p "$BMA_ROOT/configuration"
    cat > "$MY_CNF" <<EOF
[client]
user=${DB_USER}
password=${DB_PASS}
host=${DB_HOST}
port=${DB_PORT}
EOF
    chmod 600 "$MY_CNF"
    echo "[✓] Wrote $MY_CNF"
else
    echo "[*] MySQL credentials: $MY_CNF (exists)"
fi

# ─── Download JARs if needed ───
if [ ! -d "$BMA_ROOT/lib" ] || [ -z "$(ls "$BMA_ROOT/lib/"*.jar 2>/dev/null)" ]; then
    echo "[*] Downloading dependencies..."
    bash "$SCRIPT_DIR/download-jars.sh"
fi

# ─── Build WAR ───
echo "[*] Building WAR..."
bash "$BMA_ROOT/build.sh"

# ─── Install Tomcat locally ───
if [ -f "$TOMCAT_HOME/bin/catalina.sh" ]; then
    echo "[*] Tomcat already at: $TOMCAT_HOME"
else
    INSTALL_TOMCAT="y"
    [ -t 0 ] && read -rp "[?] Install Tomcat ${TOMCAT_VERSION}? [Y/n] " INSTALL_TOMCAT
    INSTALL_TOMCAT="${INSTALL_TOMCAT:-y}"

    if [[ "$INSTALL_TOMCAT" =~ ^[Yy]$ ]]; then
        echo "[*] Installing Tomcat ${TOMCAT_VERSION}..."
        cd /tmp
        curl -sfLO "$TOMCAT_URL"
        sudo mkdir -p "$TOMCAT_HOME"
        sudo tar -xzf "apache-tomcat-${TOMCAT_VERSION}.tar.gz" -C "$TOMCAT_HOME" --strip-components=1
        rm -f "apache-tomcat-${TOMCAT_VERSION}.tar.gz"

        if [ "$PLATFORM" = "linux" ]; then
            id tomcat &>/dev/null || sudo useradd -r -M -d "$TOMCAT_HOME" -s /bin/false tomcat
            sudo chown -R tomcat:tomcat "$TOMCAT_HOME"
            sudo tee /etc/systemd/system/tomcat.service > /dev/null <<EOF
[Unit]
Description=Apache Tomcat 11
After=network.target

[Service]
Type=forking
User=tomcat
Group=tomcat
Environment=JAVA_HOME=$(dirname "$(dirname "$(readlink -f "$(which java)")")")
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
            chmod +x "$TOMCAT_HOME"/bin/*.sh
            "$TOMCAT_HOME/bin/startup.sh"
        fi
        echo "[*] Tomcat ${TOMCAT_VERSION} installed and started"
    fi
fi

# ─── Deploy to local Tomcat ───
if [ -d "$TOMCAT_HOME/webapps" ]; then
    echo "[*] Deploying WAR to Tomcat: /${TOMCAT_CONTEXT}"
    sudo cp "$WAR_FILE" "$TOMCAT_HOME/webapps/${TOMCAT_CONTEXT}.war"
    sudo chown tomcat:tomcat "$TOMCAT_HOME/webapps/${TOMCAT_CONTEXT}.war" 2>/dev/null || true
    echo "[*] Tomcat will auto-deploy the WAR"
fi

echo ""
echo "[✓] Local install complete"
echo "    URL: http://localhost:8080/${TOMCAT_CONTEXT}/"
echo ""

# ─── Remote deploy option ───
echo "───────────────────────────────────────────────────────────────"
CONFIRM="n"
[ -t 0 ] && read -rp " Deploy to https://${REMOTE_DOMAIN}/brarner.m.alete? [Y/n] " CONFIRM
CONFIRM="${CONFIRM:-Y}"

if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo "[*] Starting remote deploy..."
    bash "$SCRIPT_DIR/deploy-remote-linux.sh"
else
    echo "[*] Skipped remote deploy."
    echo "    Run later: bash install/deploy-remote-linux.sh"
fi

echo "═══════════════════════════════════════════════════════════════"
