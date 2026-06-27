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

# Install Tomcat on top of Apache2 if Apache is found
echo "[*] Checking for Tomcat / installing if Apache2 already present..."
ssh "$REMOTE_USER@$REMOTE_HOST" "
    TOMCAT_VERSION='11.0.2'
    TOMCAT_HOME='/opt/tomcat'
    TOMCAT_URL=\"https://archive.apache.org/dist/tomcat/tomcat-11/v\${TOMCAT_VERSION}/bin/apache-tomcat-\${TOMCAT_VERSION}.tar.gz\"

    APACHE_FOUND=false
    TOMCAT_FOUND=false

    if systemctl is-active --quiet apache2 2>/dev/null || systemctl is-active --quiet httpd 2>/dev/null; then
        APACHE_FOUND=true
    fi

    if [ -d \"\$TOMCAT_HOME\" ] && [ -f \"\$TOMCAT_HOME/bin/catalina.sh\" ]; then
        TOMCAT_FOUND=true
    fi

    # Install Tomcat alongside Apache2
    if [ \"\$APACHE_FOUND\" = true ] && [ \"\$TOMCAT_FOUND\" = false ]; then
        echo '[*] Apache2 found — installing Tomcat '\$TOMCAT_VERSION' on top...'
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

# Configure Apache2 — ServerAlias + Tomcat proxy (if both) or static alias (Apache only)
echo "[*] Configuring Apache2 ServerAlias and routing..."
ssh "$REMOTE_USER@$REMOTE_HOST" "
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
ssh "$REMOTE_USER@$REMOTE_HOST" "
    # Install certbot
    if ! command -v certbot &>/dev/null; then
        if command -v apt &>/dev/null; then
            apt install -y certbot python3-certbot-apache
        elif command -v dnf &>/dev/null; then
            dnf install -y certbot python3-certbot-apache
        fi
    fi

    # Enable required Apache modules
    if command -v a2enmod &>/dev/null; then
        a2enmod ssl headers rewrite proxy proxy_http 2>/dev/null
    fi

    # Obtain cert from Let's Encrypt
    certbot --apache --non-interactive --agree-tos \
        --email contact@lauradei.us \
        -d lauradei.us -d www.lauradei.us \
        --redirect 2>/dev/null || echo '[*] Certbot: cert may already exist'

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

    # Enable SSL site
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
    echo '0 3 * * * root certbot renew --quiet --post-hook \"systemctl reload apache2 2>/dev/null || systemctl reload httpd 2>/dev/null\"' > /etc/cron.d/certbot-renew

    # Reload Apache
    systemctl reload apache2 2>/dev/null || systemctl reload httpd 2>/dev/null

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
