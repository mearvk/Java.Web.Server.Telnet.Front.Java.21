#!/usr/bin/env bash
# Brarner.M.Alete™ — Remote Linux Server Deploy
# Deploys website components to a known secure Linux server
# Target: http://lauradei.us/brarner.m.alete
# Server: 45.32.31.139 (mail.lauradei.us)
#
# Prerequisites: SSH key access to target server, Apache2 installed
# Usage: bash install/deploy-remote-linux.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BMA_ROOT="$(dirname "$SCRIPT_DIR")"
WEBAPP_SRC="$BMA_ROOT/servlets/servlet/src/main/webapp"

# Known secure server
REMOTE_HOST="45.32.31.139"
REMOTE_USER="${BMA_REMOTE_USER:-root}"
REMOTE_DOMAIN="lauradei.us"
REMOTE_PATH="/var/www/html/brarner.m.alete"
SITE_URL="http://${REMOTE_DOMAIN}/brarner.m.alete"

echo "═══════════════════════════════════════════════════════════════"
echo " Brarner.M.Alete™ — Remote Linux Server Deploy"
echo " Target: ${SITE_URL}"
echo " Server: ${REMOTE_HOST} (${REMOTE_DOMAIN})"
echo "═══════════════════════════════════════════════════════════════"

# Verify SSH access
echo "[*] Verifying SSH access to ${REMOTE_USER}@${REMOTE_HOST}..."
if ! ssh -o ConnectTimeout=10 -o BatchMode=yes "$REMOTE_USER@$REMOTE_HOST" "echo OK" &>/dev/null; then
    echo "[!] Cannot SSH to ${REMOTE_HOST}. Check your key or access."
    exit 1
fi
echo "[*] SSH access confirmed"

# Install Apache2 if not present
echo "[*] Ensuring Apache2 is installed..."
ssh "$REMOTE_USER@$REMOTE_HOST" "
    if ! command -v apache2 &>/dev/null && ! command -v httpd &>/dev/null; then
        if command -v apt &>/dev/null; then
            apt update && apt install -y apache2
        elif command -v dnf &>/dev/null; then
            dnf install -y httpd && systemctl enable httpd && systemctl start httpd
        fi
    fi
    systemctl enable apache2 2>/dev/null || systemctl enable httpd 2>/dev/null
    systemctl start apache2 2>/dev/null || systemctl start httpd 2>/dev/null
"

# Create directory structure on remote
echo "[*] Creating remote directory: ${REMOTE_PATH}"
ssh "$REMOTE_USER@$REMOTE_HOST" "mkdir -p ${REMOTE_PATH}/WEB-INF/lib"

# Deploy webapp
echo "[*] Deploying webapp files..."
scp -r "$WEBAPP_SRC/"* "$REMOTE_USER@$REMOTE_HOST:$REMOTE_PATH/"

# Deploy JARs
if [ -d "$BMA_ROOT/lib" ]; then
    echo "[*] Deploying library JARs..."
    scp "$BMA_ROOT/lib/"*.jar "$REMOTE_USER@$REMOTE_HOST:$REMOTE_PATH/WEB-INF/lib/" 2>/dev/null || true
fi

# Deploy images
if [ -d "$BMA_ROOT/images" ]; then
    echo "[*] Deploying images..."
    ssh "$REMOTE_USER@$REMOTE_HOST" "mkdir -p ${REMOTE_PATH}/images"
    scp -r "$BMA_ROOT/images/"* "$REMOTE_USER@$REMOTE_HOST:$REMOTE_PATH/images/" 2>/dev/null || true
fi

# Set permissions
ssh "$REMOTE_USER@$REMOTE_HOST" "chmod -R 755 ${REMOTE_PATH} && chown -R www-data:www-data ${REMOTE_PATH} 2>/dev/null || chown -R apache:apache ${REMOTE_PATH} 2>/dev/null"

# Configure Apache alias
echo "[*] Configuring Apache alias for /brarner.m.alete..."
ssh "$REMOTE_USER@$REMOTE_HOST" "
    CONF='/etc/apache2/conf-available/brarner-m-alete.conf'
    [ -d /etc/httpd/conf.d ] && CONF='/etc/httpd/conf.d/brarner-m-alete.conf'
    cat > \"\$CONF\" <<'APACHECONF'
Alias /brarner.m.alete /var/www/html/brarner.m.alete

<Directory /var/www/html/brarner.m.alete>
    Options -Indexes +FollowSymLinks
    AllowOverride All
    Require all granted
</Directory>
APACHECONF

    # Enable on Debian/Ubuntu
    if command -v a2enconf &>/dev/null; then
        a2enconf brarner-m-alete 2>/dev/null
    fi

    # Reload
    systemctl reload apache2 2>/dev/null || systemctl reload httpd 2>/dev/null
"

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo " [✓] Deploy complete"
echo " URL: ${SITE_URL}"
echo " Server: ${REMOTE_HOST}"
echo " Path: ${REMOTE_PATH}"
echo "═══════════════════════════════════════════════════════════════"
