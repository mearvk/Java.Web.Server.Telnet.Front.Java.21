#!/usr/bin/env bash
# Brarner.M.Alete™ — Remote Linux Server Deploy
# Deploys website to a known secure Linux server
# Target: https://lauradei.us/brarner.m.alete
# Server: 45.32.31.139 (mail.lauradei.us)
#
# Prerequisites: SSH key access to target server
# Usage: bash install/deploy-remote-linux.sh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BMA_ROOT="$(dirname "$SCRIPT_DIR")"
WEBAPP_SRC="$BMA_ROOT/servlets/servlet/src/main/webapp"
WAR_FILE="$BMA_ROOT/brarner.m.alete.war"

# Server config
REMOTE_HOST="45.32.31.139"
REMOTE_USER="${BMA_REMOTE_USER:-root}"
REMOTE_DOMAIN="lauradei.us"
REMOTE_PATH="/var/www/html/brarner.m.alete"
TOMCAT_CONTEXT="brarner.m.alete"
SITE_URL="https://${REMOTE_DOMAIN}/brarner.m.alete"

SSH_OPTS="-o ConnectTimeout=10 -o BatchMode=yes -o StrictHostKeyChecking=accept-new -o ServerAliveInterval=15 -o ServerAliveCountMax=3"

echo "═══════════════════════════════════════════════════════════════"
echo " Brarner.M.Alete™ — Remote Linux Server Deploy"
echo " Target: ${SITE_URL}"
echo " Server: ${REMOTE_HOST} (${REMOTE_DOMAIN})"
echo "═══════════════════════════════════════════════════════════════"

# ─── Pre-flight: Check webapp source ───
if [ ! -d "$WEBAPP_SRC" ]; then
    echo "[!] Webapp source not found: $WEBAPP_SRC"
    exit 1
fi
echo "[*] Webapp source OK"

# ─── Pre-flight: Build WAR if not present ───
if [ ! -f "$WAR_FILE" ]; then
    echo "[*] WAR not found — building..."
    bash "$BMA_ROOT/build.sh"
fi
if [ -f "$WAR_FILE" ]; then
    echo "[*] WAR file: $WAR_FILE ($(du -h "$WAR_FILE" | cut -f1))"
fi

# ─── Pre-flight: Reverse DNS ───
echo "[*] Checking reverse DNS for ${REMOTE_HOST}..."
RDNS=$(dig +short -x "$REMOTE_HOST" 2>/dev/null | head -1 || echo "")
if [ -n "$RDNS" ]; then
    echo "[*] PTR: ${REMOTE_HOST} → ${RDNS}"
else
    echo "[!] No PTR record — SSL may require manual DNS verification"
fi

# ─── Pre-flight: SSH access ───
echo "[*] Verifying SSH access to ${REMOTE_USER}@${REMOTE_HOST}..."

if ! timeout 5 bash -c "echo >/dev/tcp/${REMOTE_HOST}/22" 2>/dev/null; then
    echo "[!] Port 22 not reachable on ${REMOTE_HOST}"
    exit 1
fi

if ! ssh $SSH_OPTS "$REMOTE_USER@$REMOTE_HOST" "echo OK" 2>/dev/null; then
    echo "[!] SSH key not accepted."
    if [ ! -f ~/.ssh/id_rsa ] && [ ! -f ~/.ssh/id_ed25519 ]; then
        echo "[*] Generating ed25519 keypair..."
        mkdir -p ~/.ssh && chmod 700 ~/.ssh
        ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N "" -q
    fi
    if [ -t 0 ]; then
        ssh-copy-id -o ConnectTimeout=10 "$REMOTE_USER@$REMOTE_HOST" 2>/dev/null || \
            { echo "[!] Run: ssh-copy-id ${REMOTE_USER}@${REMOTE_HOST}"; exit 1; }
    else
        echo "[!] Run: ssh-copy-id ${REMOTE_USER}@${REMOTE_HOST}"; exit 1
    fi
fi
echo "[*] SSH access confirmed"

# ─── Install Apache2 + Java 21 + Tomcat ───
echo "[*] Ensuring Apache2, Java 21, Tomcat 11 on remote..."
ssh $SSH_OPTS "$REMOTE_USER@$REMOTE_HOST" '
    set -e

    # Apache2
    if ! command -v apache2 &>/dev/null && ! command -v httpd &>/dev/null; then
        if command -v apt &>/dev/null; then
            DEBIAN_FRONTEND=noninteractive apt update -qq
            DEBIAN_FRONTEND=noninteractive apt install -y -qq apache2
        elif command -v dnf &>/dev/null; then
            dnf install -y httpd && systemctl enable httpd
        fi
    fi
    systemctl enable apache2 2>/dev/null || systemctl enable httpd 2>/dev/null
    systemctl start apache2 2>/dev/null || systemctl start httpd 2>/dev/null

    # Java 21
    if ! java -version 2>&1 | grep -q "21\|22\|23"; then
        if command -v apt &>/dev/null; then
            DEBIAN_FRONTEND=noninteractive apt install -y -qq openjdk-21-jre-headless
        elif command -v dnf &>/dev/null; then
            dnf install -y java-21-openjdk-headless
        fi
    fi

    # Tomcat 11
    TOMCAT_HOME="/opt/tomcat"
    if [ ! -f "$TOMCAT_HOME/bin/catalina.sh" ]; then
        TOMCAT_VERSION="11.0.2"
        cd /tmp
        curl -sfLO "https://archive.apache.org/dist/tomcat/tomcat-11/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz"
        mkdir -p "$TOMCAT_HOME"
        tar -xzf "apache-tomcat-${TOMCAT_VERSION}.tar.gz" -C "$TOMCAT_HOME" --strip-components=1
        rm -f "apache-tomcat-${TOMCAT_VERSION}.tar.gz"
        id tomcat &>/dev/null || useradd -r -M -d "$TOMCAT_HOME" -s /bin/false tomcat
        chown -R tomcat:tomcat "$TOMCAT_HOME"
        chmod +x "$TOMCAT_HOME"/bin/*.sh

        # Bind Tomcat to localhost only
        if grep -q "address=" "$TOMCAT_HOME/conf/server.xml"; then
            sed -i '"'"'s/Connector port="8080" address="[^"]*"/Connector port="8080" address="127.0.0.1"/'"'"' "$TOMCAT_HOME/conf/server.xml"
        else
            sed -i '"'"'s/Connector port="8080"/Connector port="8080" address="127.0.0.1"/'"'"' "$TOMCAT_HOME/conf/server.xml"
        fi

        cat > /etc/systemd/system/tomcat.service <<EOF
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
EOF
        systemctl daemon-reload
        systemctl enable tomcat
        systemctl start tomcat
        echo "[*] Tomcat 11 installed (127.0.0.1:8080)"
    else
        echo "[*] Tomcat already present"
        systemctl start tomcat 2>/dev/null || true
    fi
'

# ─── Deploy WAR to Tomcat ───
echo "[*] Deploying to Tomcat context: /${TOMCAT_CONTEXT}"
ssh $SSH_OPTS "$REMOTE_USER@$REMOTE_HOST" "rm -rf /opt/tomcat/webapps/${TOMCAT_CONTEXT} /opt/tomcat/webapps/${TOMCAT_CONTEXT}.war"

if [ -f "$WAR_FILE" ]; then
    scp -o ConnectTimeout=10 -o BatchMode=yes "$WAR_FILE" "$REMOTE_USER@$REMOTE_HOST:/opt/tomcat/webapps/${TOMCAT_CONTEXT}.war"
else
    # Fallback: deploy exploded webapp
    ssh $SSH_OPTS "$REMOTE_USER@$REMOTE_HOST" "mkdir -p /opt/tomcat/webapps/${TOMCAT_CONTEXT}/WEB-INF/lib"
    scp -o ConnectTimeout=10 -o BatchMode=yes -r "$WEBAPP_SRC/"* "$REMOTE_USER@$REMOTE_HOST:/opt/tomcat/webapps/${TOMCAT_CONTEXT}/"
    if [ -d "$BMA_ROOT/lib" ]; then
        scp -o ConnectTimeout=10 -o BatchMode=yes "$BMA_ROOT/lib/mysql-connector-j-"*.jar "$REMOTE_USER@$REMOTE_HOST:/opt/tomcat/webapps/${TOMCAT_CONTEXT}/WEB-INF/lib/" 2>/dev/null || true
    fi
fi

ssh $SSH_OPTS "$REMOTE_USER@$REMOTE_HOST" "chown -R tomcat:tomcat /opt/tomcat/webapps/${TOMCAT_CONTEXT}* && systemctl restart tomcat"
echo "[*] Tomcat restarted with new deployment"

# ─── Deploy static copy for Apache (images served directly) ───
echo "[*] Deploying static assets to ${REMOTE_PATH}..."
ssh $SSH_OPTS "$REMOTE_USER@$REMOTE_HOST" "mkdir -p ${REMOTE_PATH}/{images,css}"
scp -o ConnectTimeout=10 -o BatchMode=yes -r "$WEBAPP_SRC/images/"* "$REMOTE_USER@$REMOTE_HOST:$REMOTE_PATH/images/"
scp -o ConnectTimeout=10 -o BatchMode=yes "$WEBAPP_SRC/css/style.css" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_PATH/css/"
ssh $SSH_OPTS "$REMOTE_USER@$REMOTE_HOST" "chmod -R 755 $REMOTE_PATH && chown -R www-data:www-data $REMOTE_PATH 2>/dev/null || chown -R apache:apache $REMOTE_PATH"

# ─── Apache2 config: proxy to Tomcat + serve static images directly ───
echo "[*] Configuring Apache2 proxy → Tomcat..."
ssh $SSH_OPTS "$REMOTE_USER@$REMOTE_HOST" '
    set -e

    # Enable modules
    if command -v a2enmod &>/dev/null; then
        a2enmod proxy proxy_http ssl headers rewrite 2>/dev/null
    fi

    # Proxy config
    CONF="/etc/apache2/conf-available/brarner-m-alete.conf"
    [ -d /etc/httpd/conf.d ] && CONF="/etc/httpd/conf.d/brarner-m-alete.conf"

    cat > "$CONF" <<'"'"'APACHECONF'"'"'
# Brarner.M.Alete™ — Apache2 → Tomcat proxy

# Static assets served by Apache directly (faster)
Alias /brarner.m.alete/images /var/www/html/brarner.m.alete/images
Alias /brarner.m.alete/css /var/www/html/brarner.m.alete/css

<Directory /var/www/html/brarner.m.alete>
    Options -Indexes
    Require all granted
</Directory>

# Everything else proxied to Tomcat
ProxyPass /brarner.m.alete/images !
ProxyPass /brarner.m.alete/css !
ProxyPass /brarner.m.alete http://127.0.0.1:8080/brarner.m.alete
ProxyPassReverse /brarner.m.alete http://127.0.0.1:8080/brarner.m.alete
APACHECONF

    if command -v a2enconf &>/dev/null; then
        a2enconf brarner-m-alete 2>/dev/null
    fi
    systemctl reload apache2 2>/dev/null || systemctl reload httpd 2>/dev/null
'

# ─── SSL via Let's Encrypt ───
echo "[*] Configuring SSL/TLS (Let's Encrypt)..."
ssh $SSH_OPTS "$REMOTE_USER@$REMOTE_HOST" '
    set -e

    # Install certbot
    if ! command -v certbot &>/dev/null; then
        if command -v apt &>/dev/null; then
            DEBIAN_FRONTEND=noninteractive apt install -y -qq certbot python3-certbot-apache
        elif command -v dnf &>/dev/null; then
            dnf install -y certbot python3-certbot-apache
        fi
    fi

    # Get cert if not already present
    if [ -f /etc/letsencrypt/live/lauradei.us/fullchain.pem ]; then
        echo "[*] SSL cert already exists — skipping"
    else
        echo "[*] Obtaining cert from Let'\''s Encrypt..."
        certbot --apache --non-interactive --agree-tos \
            --email contact@lauradei.us \
            -d lauradei.us -d www.lauradei.us 2>&1 || {
            echo "[!] certbot --apache failed, trying standalone..."
            systemctl stop apache2 2>/dev/null || true
            certbot certonly --standalone --non-interactive --agree-tos \
                --email contact@lauradei.us \
                -d lauradei.us -d www.lauradei.us
            systemctl start apache2 2>/dev/null || true
        }
    fi

    # Verify cert
    if [ ! -f /etc/letsencrypt/live/lauradei.us/fullchain.pem ]; then
        echo "[!] SSL cert not obtained — running HTTP only"
        echo "    Check: DNS A record, ports 80/443 open"
        exit 0
    fi

    # SSL VirtualHost
    SSL_CONF="/etc/apache2/sites-available/brarner-ssl.conf"
    [ -d /etc/httpd/conf.d ] && SSL_CONF="/etc/httpd/conf.d/brarner-ssl.conf"

    cat > "$SSL_CONF" <<'"'"'SSLCONF'"'"'
<IfModule mod_ssl.c>
<VirtualHost *:443>
    ServerName lauradei.us
    ServerAlias www.lauradei.us

    SSLEngine on
    SSLCertificateFile /etc/letsencrypt/live/lauradei.us/fullchain.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/lauradei.us/privkey.pem

    Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains"

    # Static assets
    Alias /brarner.m.alete/images /var/www/html/brarner.m.alete/images
    Alias /brarner.m.alete/css /var/www/html/brarner.m.alete/css
    <Directory /var/www/html/brarner.m.alete>
        Options -Indexes
        Require all granted
    </Directory>

    # Proxy to Tomcat
    ProxyPass /brarner.m.alete/images !
    ProxyPass /brarner.m.alete/css !
    ProxyPass /brarner.m.alete http://127.0.0.1:8080/brarner.m.alete
    ProxyPassReverse /brarner.m.alete http://127.0.0.1:8080/brarner.m.alete
</VirtualHost>
</IfModule>
SSLCONF

    # HTTP→HTTPS redirect
    REDIR="/etc/apache2/sites-available/brarner-redirect.conf"
    [ -d /etc/httpd/conf.d ] && REDIR="/etc/httpd/conf.d/brarner-redirect.conf"
    cat > "$REDIR" <<'"'"'REDIRCONF'"'"'
<VirtualHost *:80>
    ServerName lauradei.us
    ServerAlias www.lauradei.us
    RewriteEngine On
    RewriteCond %{HTTPS} off
    RewriteRule ^(.*)$ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]
</VirtualHost>
REDIRCONF

    if command -v a2ensite &>/dev/null; then
        a2ensite brarner-ssl brarner-redirect 2>/dev/null
    fi

    # Auto-renewal
    echo "0 3 * * * root certbot renew --quiet --deploy-hook \"systemctl reload apache2 2>/dev/null || systemctl reload httpd 2>/dev/null\"" > /etc/cron.d/certbot-renew

    systemctl restart apache2 2>/dev/null || systemctl restart httpd 2>/dev/null
    echo "[*] SSL configured — HTTP→HTTPS redirect active"
'

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo " [✓] Deploy complete"
echo ""
echo " URL:     ${SITE_URL}"
echo " Server:  ${REMOTE_HOST}"
echo " Ports:   80 (→301) | 443 (SSL) | 8080 (localhost only)"
echo " Tomcat:  /opt/tomcat/webapps/${TOMCAT_CONTEXT}"
echo " Static:  ${REMOTE_PATH}/images, ${REMOTE_PATH}/css"
echo " Cert:    Let's Encrypt (auto-renew 03:00 daily)"
echo ""
echo " Verify:  bash install/test-remote.sh"
echo "═══════════════════════════════════════════════════════════════"
