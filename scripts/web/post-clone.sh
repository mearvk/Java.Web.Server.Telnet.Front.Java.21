#!/bin/bash
# NitroWebExpress™ — Post-Clone Setup (Linux)
# Run once after cloning the repository. Installs dependencies, deploys all webapps.
# Usage: sudo bash scripts/web/post-clone.sh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

echo "═══════════════════════════════════════════════════════════════"
echo " NitroWebExpress™ — Post-Clone Setup (Linux)"
echo "═══════════════════════════════════════════════════════════════"

# 1. Ensure Java 21
if ! java -version 2>&1 | grep -q "21\|22\|23"; then
    echo "[*] Installing Java 21..."
    apt update -qq && apt install -y -qq openjdk-21-jre-headless 2>/dev/null || \
    dnf install -y java-21-openjdk-headless 2>/dev/null || true
fi
echo "[OK] Java: $(java -version 2>&1 | head -1)"

# 2. Ensure MySQL
if ! command -v mysql &>/dev/null; then
    echo "[*] Installing MySQL..."
    apt install -y -qq mysql-server 2>/dev/null || dnf install -y mysql-server 2>/dev/null || true
    systemctl enable mysql 2>/dev/null || systemctl enable mysqld 2>/dev/null
    systemctl start mysql 2>/dev/null || systemctl start mysqld 2>/dev/null
fi
echo "[OK] MySQL: $(mysql --version 2>/dev/null | head -1)"

# 3. Configure MySQL root for JDBC
echo "[*] Configuring MySQL root for JDBC (caching_sha2_password)..."
sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH caching_sha2_password BY '\$\$Ironman1'; FLUSH PRIVILEGES;" 2>/dev/null || true

# 4. Ensure Tomcat
TOMCAT_HOME="/home/mearvk/tomcat"
if [ ! -f "$TOMCAT_HOME/bin/catalina.sh" ]; then
    echo "[*] Installing Tomcat 11..."
    cd /tmp && curl -sfLO "https://archive.apache.org/dist/tomcat/tomcat-11/v11.0.2/bin/apache-tomcat-11.0.2.tar.gz"
    mkdir -p "$TOMCAT_HOME" && tar -xzf apache-tomcat-11.0.2.tar.gz -C "$TOMCAT_HOME" --strip-components=1
    rm -f apache-tomcat-11.0.2.tar.gz
    id tomcat &>/dev/null || useradd -r -M -d "$TOMCAT_HOME" -s /bin/false tomcat
    chown -R tomcat:tomcat "$TOMCAT_HOME" && chmod +x "$TOMCAT_HOME"/bin/*.sh
fi
echo "[OK] Tomcat: $TOMCAT_HOME"

# 5. Make all scripts executable
find "$PROJECT_ROOT" -name "*.sh" -exec chmod +x {} \;
echo "[OK] Scripts: chmod +x applied"

# 5.1. Install UFW and open all NWE ports
echo ""
echo "[*] Configuring firewall — installing UFW and opening all NWE service ports..."
source "$PROJECT_ROOT/scripts/nwe-ports.sh"
nwe_ensure_ufw
nwe_open_ports
echo "[OK] Firewall configured"

# 5.5. Setup module databases
echo ""
echo "[*] Setting up module databases..."
SETUP_SCRIPTS=(
    "modules/fbi/servlets/setup-db.sh"
    "modules/cia/servlets/setup-db.sh"
    "modules/nsa/servlets/setup-db.sh"
    "modules/duke/servlets/setup-db.sh"
    "modules/library/servlets/setup-db.sh"
)
for SETUP in "${SETUP_SCRIPTS[@]}"; do
    FULL="$PROJECT_ROOT/$SETUP"
    if [ -f "$FULL" ]; then
        bash "$FULL" 2>/dev/null && echo "  [OK] $SETUP" || echo "  [WARN] $SETUP (MySQL may not be ready)"
    fi
done

# 6. Deploy all web modules
echo ""
bash "$SCRIPT_DIR/deploy-all.sh"

# 7. Start Tomcat
systemctl start tomcat 2>/dev/null || "$TOMCAT_HOME/bin/startup.sh"
echo "[OK] Tomcat started"

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo " Post-clone setup complete."
echo " All modules: http://localhost:8080/"
echo "═══════════════════════════════════════════════════════════════"
