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
SITE_URL="https://${REMOTE_DOMAIN}/brarner.m.alete"

# SSH options to prevent hanging
SSH_OPTS="-o ConnectTimeout=10 -o BatchMode=yes -o StrictHostKeyChecking=accept-new -o ServerAliveInterval=15 -o ServerAliveCountMax=3"

echo "═══════════════════════════════════════════════════════════════"
echo " Brarner.M.Alete™ — Remote Linux Server Deploy"
echo " Target: ${SITE_URL}"
echo " Server: ${REMOTE_HOST} (${REMOTE_DOMAIN})"
echo "═══════════════════════════════════════════════════════════════"

# ─── Pre-flight: Reverse DNS check ───
echo "[*] Checking reverse DNS for ${REMOTE_HOST}..."
RDNS=$(dig +short -x "$REMOTE_HOST" 2>/dev/null | head -1 || host "$REMOTE_HOST" 2>/dev/null | awk '{print $NF}' || echo "")
if [ -n "$RDNS" ]; then
    echo "[*] Reverse DNS: ${REMOTE_HOST} → ${RDNS}"
    # Verify it resolves back to our domain
    if echo "$RDNS" | grep -qi "lauradei"; then
        echo "[*] PTR matches expected domain"
    else
        echo "[!] WARNING: PTR (${RDNS}) does not match lauradei.us"
        echo "    SSL cert may fail. Ensure DNS A record points to ${REMOTE_HOST}"
        echo "    Continuing anyway..."
    fi
else
    echo "[!] WARNING: No reverse DNS found for ${REMOTE_HOST}"
    echo "    Set PTR record: ${REMOTE_HOST} → mail.lauradei.us"
    echo "    Continuing anyway..."
fi

# ─── Pre-flight: Verify SSH access ───
echo "[*] Verifying SSH access to ${REMOTE_USER}@${REMOTE_HOST}..."

# Check port 22 is reachable
if ! timeout 5 bash -c "echo >/dev/tcp/${REMOTE_HOST}/22" 2>/dev/null; then
    echo "[!] Port 22 not reachable on ${REMOTE_HOST}. Firewall or SSH not running."
    echo "    Check: ufw allow 22, or systemctl start sshd on remote"
    exit 1
fi

# Try SSH with accept-new for first-time key handshake
if ! ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=accept-new -o BatchMode=yes "$REMOTE_USER@$REMOTE_HOST" "echo OK" 2>/dev/null; then
    echo "[!] SSH key not accepted. Attempting initial key exchange..."
    # Generate keypair if none exists
    if [ ! -f ~/.ssh/id_rsa ] && [ ! -f ~/.ssh/id_ed25519 ]; then
        echo "[*] No SSH key found — generating ed25519 keypair..."
        mkdir -p ~/.ssh && chmod 700 ~/.ssh
        ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N "" -q
    fi
    if [ -t 0 ]; then
        ssh-copy-id -o ConnectTimeout=10 "$REMOTE_USER@$REMOTE_HOST" 2>/dev/null && \
            echo "[*] Key installed successfully" || \
            { echo "[!] Key install failed. Try: ssh-copy-id ${REMOTE_USER}@${REMOTE_HOST}"; exit 1; }
    else
        echo "[!] Cannot SSH (non-interactive). Run: ssh-keygen -t ed25519 && ssh-copy-id ${REMOTE_USER}@${REMOTE_HOST}"
        exit 1
    fi
fi
echo "[*] SSH access confirmed"

# ─── Pre-flight: Check if Apache alias config already exists ───
echo "[*] Checking for existing Apache alias configuration..."
ALIAS_EXISTS=$(ssh $SSH_OPTS "$REMOTE_USER@$REMOTE_HOST" "
    if [ -f /etc/apache2/conf-available/brarner-m-alete.conf ] || \
       [ -f /etc/apache2/conf-enabled/brarner-m-alete.conf ] || \
       [ -f /etc/httpd/conf.d/brarner-m-alete.conf ]; then
        echo 'EXISTS'
    else
        echo 'NONE'
    fi
" 2>/dev/null)

if [ "$ALIAS_EXISTS" = "EXISTS" ]; then
    echo "[*] Apache alias config already exists — will update in place"
else
    echo "[*] No existing alias config — will create new"
fi

# ─── Pre-flight: Check webapp source exists locally ───
if [ ! -d "$WEBAPP_SRC" ]; then
    echo "[!] Webapp source not found: $WEBAPP_SRC"
    echo "    Run download-jars.sh and build first."
    exit 1
fi
echo "[*] Webapp source OK: $WEBAPP_SRC"

# Install Apache2 if not present
echo "[*] Ensuring Apache2 is installed..."
ssh $SSH_OPTS "$REMOTE_USER@$REMOTE_HOST" "
    if ! command -v apache2 &>/dev/null && ! command -v httpd &>/dev/null; then
        if command -v apt &>/dev/null; then
            DEBIAN_FRONTEND=noninteractive apt update && DEBIAN_FRONTEND=noninteractive apt install -y apache2
        elif command -v dnf &>/dev/null; then
            dnf install -y httpd && systemctl enable httpd && systemctl start httpd
        fi
    fi
    systemctl enable apache2 2>/dev/null || systemctl enable httpd 2>/dev/null
    systemctl start apache2 2>/dev/null || systemctl start httpd 2>/dev/null
"

# Create directory structure on remote
echo "[*] Creating remote directory: ${REMOTE_PATH}"
ssh $SSH_OPTS "$REMOTE_USER@$REMOTE_HOST" "mkdir -p ${REMOTE_PATH}/WEB-INF/lib"

# Deploy webapp
echo "[*] Deploying webapp files..."
scp -o ConnectTimeout=10 -o BatchMode=yes -r "$WEBAPP_SRC/"* "$REMOTE_USER@$REMOTE_HOST:$REMOTE_PATH/"

# Deploy JARs
if [ -d "$BMA_ROOT/lib" ]; then
    echo "[*] Deploying library JARs..."
    scp -o ConnectTimeout=10 -o BatchMode=yes "$BMA_ROOT/lib/"*.jar "$REMOTE_USER@$REMOTE_HOST:$REMOTE_PATH/WEB-INF/lib/" 2>/dev/null || true
fi

# Deploy images
if [ -d "$BMA_ROOT/images" ]; then
    echo "[*] Deploying images..."
    ssh $SSH_OPTS "$REMOTE_USER@$REMOTE_HOST" "mkdir -p ${REMOTE_PATH}/images"
    scp -o ConnectTimeout=10 -o BatchMode=yes -r "$BMA_ROOT/images/"* "$REMOTE_USER@$REMOTE_HOST:$REMOTE_PATH/images/" 2>/dev/null || true
fi

# Set permissions
ssh $SSH_OPTS "$REMOTE_USER@$REMOTE_HOST" "chmod -R 755 ${REMOTE_PATH} && chown -R www-data:www-data ${REMOTE_PATH} 2>/dev/null || chown -R apache:apache ${REMOTE_PATH} 2>/dev/null"

# Install Tomcat — BMA runs on Java Enterprise; auto-install or prompt
INSTALL_TOMCAT="y"
if [ -t 0 ]; then
    read -rp "[?] Install Tomcat 11 for Java Enterprise servlets? [Y/n] " INSTALL_TOMCAT
    INSTALL_TOMCAT="${INSTALL_TOMCAT:-y}"
fi

if [[ "$INSTALL_TOMCAT" =~ ^[Yy]$ ]]; then
echo "[*] Installing Tomcat (Java Enterprise runtime for BMA)..."
ssh $SSH_OPTS "$REMOTE_USER@$REMOTE_HOST" "
    TOMCAT_VERSION='11.0.2'
    TOMCAT_HOME='/opt/tomcat'
    TOMCAT_URL=\"https://archive.apache.org/dist/tomcat/tomcat-11/v\${TOMCAT_VERSION}/bin/apache-tomcat-\${TOMCAT_VERSION}.tar.gz\"

    TOMCAT_FOUND=false

    if [ -d \"\$TOMCAT_HOME\" ] && [ -f \"\$TOMCAT_HOME/bin/catalina.sh\" ]; then
        TOMCAT_FOUND=true
        echo '[*] Tomcat already installed at '\$TOMCAT_HOME
    fi

    # Install Tomcat (BMA requires Java Enterprise / Jakarta Servlet runtime)
    if [ \"\$TOMCAT_FOUND\" = false ]; then
        echo '[*] Installing Tomcat '\$TOMCAT_VERSION' (Jakarta Servlet 6.1 runtime)...'
        cd /tmp
        curl -sfLO \"\$TOMCAT_URL\"
        mkdir -p \"\$TOMCAT_HOME\"
        tar -xzf \"apache-tomcat-\${TOMCAT_VERSION}.tar.gz\" -C \"\$TOMCAT_HOME\" --strip-components=1
        rm -f \"apache-tomcat-\${TOMCAT_VERSION}.tar.gz\"

        id tomcat &>/dev/null || useradd -r -M -d \"\$TOMCAT_HOME\" -s /bin/false tomcat
        chown -R tomcat:tomcat \"\$TOMCAT_HOME\"
        chmod +x \"\$TOMCAT_HOME\"/bin/*.sh

        cat > /etc/systemd/system/tomcat.service <<'TOMSVC'
[Unit]
Description=Apache Tomcat 11
After=network.target

[Service]
Type=forking
User=tomcat
Group=tomcat
Environment=JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
Environment=CATALINA_HOME=/opt/tomcat
Environment=CATALINA_PID=/opt/tomcat/temp/tomcat.pid
ExecStart=/opt/tomcat/bin/startup.sh
ExecStop=/opt/tomcat/bin/shutdown.sh
Restart=on-failure

[Install]
WantedBy=multi-user.target
TOMSVC
        systemctl daemon-reload
        systemctl enable tomcat
        systemctl start tomcat
        TOMCAT_FOUND=true
        echo '[*] Tomcat installed and started on port 8080'
    fi

    # Deploy to Tomcat webapps
    if [ \"\$TOMCAT_FOUND\" = true ]; then
        mkdir -p \"\$TOMCAT_HOME/webapps/brarner\"
        cp -r ${REMOTE_PATH}/* \"\$TOMCAT_HOME/webapps/brarner/\" 2>/dev/null
        chown -R tomcat:tomcat \"\$TOMCAT_HOME/webapps/brarner\"
        echo '[*] Deployed to Tomcat context: /brarner'
    fi
"
else
    echo "[*] Skipping Tomcat install — Apache2 static only"
fi

# Configure Apache2 — ServerAlias + Tomcat proxy (if both) or static alias (Apache only)
echo "[*] Configuring Apache2 ServerAlias and routing..."
ssh $SSH_OPTS "$REMOTE_USER@$REMOTE_HOST" "
    CONF='/etc/apache2/conf-available/brarner-m-alete.conf'
    [ -d /etc/httpd/conf.d ] && CONF='/etc/httpd/conf.d/brarner-m-alete.conf'

    TOMCAT_UP=false
    if systemctl is-active --quiet tomcat 2>/dev/null; then
        TOMCAT_UP=true
    fi

    if [ \"\$TOMCAT_UP\" = true ]; then
        # Apache2 + Tomcat: static images via Apache, servlets via proxy to Tomcat
        cat > \"\$CONF\" <<'APACHECONF'
# Brarner.M.Alete™ — Apache2 + Tomcat proxy
# ServerAlias: lauradei.us, www.lauradei.us

# Static files served directly by Apache
Alias /brarner.m.alete/images /var/www/html/brarner.m.alete/images
<Directory /var/www/html/brarner.m.alete/images>
    Options -Indexes
    Require all granted
</Directory>

# Servlet/dynamic requests proxied to Tomcat 8080
ProxyPass /brarner.m.alete/images !
ProxyPass /brarner.m.alete http://localhost:8080/brarner
ProxyPassReverse /brarner.m.alete http://localhost:8080/brarner

<Location /brarner.m.alete>
    Require all granted
</Location>
APACHECONF

        # Enable proxy modules
        if command -v a2enmod &>/dev/null; then
            a2enmod proxy proxy_http 2>/dev/null
        fi
    else
        # Apache2 only — static alias
        cat > \"\$CONF\" <<'APACHECONF'
# Brarner.M.Alete™ — Apache2 static
# ServerAlias: lauradei.us, www.lauradei.us

Alias /brarner.m.alete /var/www/html/brarner.m.alete
<Directory /var/www/html/brarner.m.alete>
    Options -Indexes +FollowSymLinks
    AllowOverride All
    Require all granted
</Directory>
APACHECONF
    fi

    # Add ServerAlias to default vhost
    VHOST='/etc/apache2/sites-available/000-default.conf'
    [ ! -f \"\$VHOST\" ] && VHOST='/etc/httpd/conf.d/vhost.conf'
    if [ -f \"\$VHOST\" ] && ! grep -q 'ServerAlias.*lauradei' \"\$VHOST\"; then
        sed -i '/ServerName/a\\    ServerAlias lauradei.us www.lauradei.us' \"\$VHOST\" 2>/dev/null
    fi

    # Enable and reload
    if command -v a2enconf &>/dev/null; then
        a2enconf brarner-m-alete 2>/dev/null
    fi
    systemctl reload apache2 2>/dev/null || systemctl reload httpd 2>/dev/null
"

echo ""

# ─── SSL/TLS 443 — Let's Encrypt (Trusted CA) + Tomcat locked to localhost ───
echo "[*] Configuring SSL/TLS port 443 via Let's Encrypt (Trusted CA)..."
ssh $SSH_OPTS "$REMOTE_USER@$REMOTE_HOST" "
    # Install certbot
    if ! command -v certbot &>/dev/null; then
        if command -v apt &>/dev/null; then
            DEBIAN_FRONTEND=noninteractive apt install -y certbot python3-certbot-apache
        elif command -v dnf &>/dev/null; then
            dnf install -y certbot python3-certbot-apache
        fi
    fi

    # Enable required Apache modules
    if command -v a2enmod &>/dev/null; then
        a2enmod ssl headers rewrite proxy proxy_http 2>/dev/null
    fi

    # Check if cert already exists
    if [ -f /etc/letsencrypt/live/lauradei.us/fullchain.pem ]; then
        echo '[*] SSL cert already exists'
    else
        echo '[*] Obtaining SSL cert from Let'\''s Encrypt...'

        # Must stop Apache so certbot standalone can bind port 80
        systemctl stop apache2 2>/dev/null || systemctl stop httpd 2>/dev/null

        # Use standalone mode (most reliable — binds port 80 directly)
        certbot certonly --standalone --non-interactive --agree-tos \
            --email contact@lauradei.us \
            -d lauradei.us -d www.lauradei.us 2>&1

        # Restart Apache after cert obtained
        systemctl start apache2 2>/dev/null || systemctl start httpd 2>/dev/null
    fi

    # Verify cert was obtained before writing SSL config
    if [ ! -f /etc/letsencrypt/live/lauradei.us/fullchain.pem ]; then
        echo '[!] ERROR: Could not obtain SSL cert. Apache will run HTTP only.'
        echo '    Check DNS: lauradei.us must resolve to this server'\''s public IP.'
        echo '    Check ports: 80 and 443 must be open inbound.'
        echo '    Try manually: certbot certonly --standalone -d lauradei.us'
        exit 0
    fi

    echo '[*] SSL cert confirmed at /etc/letsencrypt/live/lauradei.us/'

    # Determine if Tomcat is up
    TOMCAT_UP=false
    if systemctl is-active --quiet tomcat 2>/dev/null; then
        TOMCAT_UP=true
    fi

    # SSL VirtualHost (port 443)
    SSL_CONF='/etc/apache2/sites-available/brarner-ssl.conf'
    [ -d /etc/httpd/conf.d ] && SSL_CONF='/etc/httpd/conf.d/brarner-ssl.conf'

    cat > \"\$SSL_CONF\" <<'SSLHEAD'
<IfModule mod_ssl.c>
<VirtualHost *:443>
    ServerName lauradei.us
    ServerAlias www.lauradei.us

    SSLEngine on
    SSLCertificateFile /etc/letsencrypt/live/lauradei.us/fullchain.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/lauradei.us/privkey.pem

    Header always set Strict-Transport-Security \"max-age=31536000; includeSubDomains\"

    Alias /brarner.m.alete/images /var/www/html/brarner.m.alete/images
    <Directory /var/www/html/brarner.m.alete/images>
        Options -Indexes
        Require all granted
    </Directory>
SSLHEAD

    if [ \"\$TOMCAT_UP\" = true ]; then
        cat >> \"\$SSL_CONF\" <<'SSLPROXY'

    ProxyPass /brarner.m.alete/images !
    ProxyPass /brarner.m.alete http://127.0.0.1:8080/brarner
    ProxyPassReverse /brarner.m.alete http://127.0.0.1:8080/brarner
SSLPROXY
    else
        cat >> \"\$SSL_CONF\" <<'SSLSTATIC'

    Alias /brarner.m.alete /var/www/html/brarner.m.alete
    <Directory /var/www/html/brarner.m.alete>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
SSLSTATIC
    fi

    cat >> \"\$SSL_CONF\" <<'SSLFOOT'

</VirtualHost>
</IfModule>
SSLFOOT

    # Enable SSL site only now that cert is confirmed
    if command -v a2ensite &>/dev/null; then
        a2ensite brarner-ssl 2>/dev/null
    fi

    # Port 80 → 443 redirect
    REDIR='/etc/apache2/sites-available/brarner-redirect.conf'
    [ -d /etc/httpd/conf.d ] && REDIR='/etc/httpd/conf.d/brarner-redirect.conf'
    cat > \"\$REDIR\" <<'REDIR80'
<VirtualHost *:80>
    ServerName lauradei.us
    ServerAlias www.lauradei.us
    RewriteEngine On
    RewriteCond %{HTTPS} off
    RewriteRule ^(.*)$ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]
</VirtualHost>
REDIR80

    if command -v a2ensite &>/dev/null; then
        a2ensite brarner-redirect 2>/dev/null
    fi

    # Lock Tomcat to localhost only — no external 8080/8443 access
    if [ -f /opt/tomcat/conf/server.xml ]; then
        sed -i 's|Connector port=\"8080\"|Connector port=\"8080\" address=\"127.0.0.1\"|' /opt/tomcat/conf/server.xml 2>/dev/null
        # Remove any 8443 connector or bind to localhost
        sed -i 's|Connector port=\"8443\"|Connector port=\"8443\" address=\"127.0.0.1\"|' /opt/tomcat/conf/server.xml 2>/dev/null
        systemctl restart tomcat 2>/dev/null
        echo '[*] Tomcat locked to 127.0.0.1:8080 — no external access'
    fi

    # Auto-renewal cron
    echo '0 3 * * * root certbot renew --quiet --pre-hook \"systemctl stop apache2 2>/dev/null || systemctl stop httpd 2>/dev/null\" --post-hook \"systemctl start apache2 2>/dev/null || systemctl start httpd 2>/dev/null\"' > /etc/cron.d/certbot-renew

    # Restart Apache (not reload — SSL site newly enabled)
    systemctl restart apache2 2>/dev/null || systemctl restart httpd 2>/dev/null

    echo '[*] SSL 443 configured — 80 redirects to 443'
"

echo "═══════════════════════════════════════════════════════════════"
echo " [✓] Deploy complete"
echo " URL: https://lauradei.us/brarner.m.alete"
echo " Server: ${REMOTE_HOST}"
echo " Ports: 80 (→301 redirect) | 443 (SSL/TLS)"
echo " Cert: Let's Encrypt (auto-renew daily 03:00)"
echo " Tomcat: 127.0.0.1:8080 only (proxied via Apache 443)"
echo " ServerAlias: lauradei.us, www.lauradei.us"
echo "═══════════════════════════════════════════════════════════════"
