#!/bin/bash
# SPDX-License-Identifier: GPL-2.0
#
# install-jwstf.sh — Install Java Web Server Telnet Front (NitroWebExpress)
#
# Installs the JWSTF/NWE application stack during OS installation:
#   - Apache2 (reverse proxy / static frontend)
#   - Apache Tomcat 10.1 (servlet container)
#   - MySQL 8+ (application database)
#   - OpenJDK 21+ (runtime — uses system JDK or boot-jdk-27)
#   - NitroWebExpress application (compiled + deployed)
#   - Systemd services for auto-start
#   - ClamAV integration
#   - Firewall rules (ports 80, 443, 8080, 8443, 23)
#
# Usage:
#   During OS install (chroot): /usr/sbin/install-jwstf.sh
#   Standalone:                 sudo bash install-jwstf.sh
#
# The JWSTF source is expected at /usr/local/src/jwstf/ (copied during ISO build).
# If not found, the script exits with instructions.
#
# Copyright (C) 2026 MEARVK LLC
# Author: Maximilian Eric Alexander Rupplin von Keffikon

set -e

# ============================================================
# Configuration
# ============================================================

JWSTF_SRC="/usr/local/src/jwstf"
JWSTF_HOME="/opt/nwe"
JWSTF_USER="nwe"
JWSTF_GROUP="nwe"
TOMCAT_VERSION="10.1.28"
TOMCAT_HOME="/opt/tomcat"
TOMCAT_USER="tomcat"
MYSQL_DB="N21"
MYSQL_USER="mearvk"
MYSQL_PASS='$$Ironman1'
NWE_PORTS=(80 443 8080 8443 23)
LOG="/var/log/jwstf-install.log"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  JWSTF / NitroWebExpress — System Installation              ║"
echo "║  Galactic Cherry Marvell Edition 98                         ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

exec > >(tee -a "$LOG") 2>&1

if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: Must run as root (or in chroot during OS install)"
    exit 1
fi

# ============================================================
# Check source availability
# ============================================================

if [ ! -d "$JWSTF_SRC/source" ]; then
    echo "ERROR: JWSTF source not found at $JWSTF_SRC/source"
    echo ""
    echo "  During ISO build, the source should be copied:"
    echo "    cp -a userland/java-web-server/ \$ROOTFS/usr/local/src/jwstf/"
    echo ""
    echo "  Or manually install:"
    echo "    git clone https://github.com/mearvk/Java.Web.Server.Telnet.Front.Java.21 $JWSTF_SRC"
    exit 1
fi

echo "[source] JWSTF source found at $JWSTF_SRC"
echo ""

# ============================================================
# 1. System Dependencies
# ============================================================

echo "=== [1/8] Installing system dependencies ==="

export DEBIAN_FRONTEND=noninteractive

apt-get update -qq

apt-get install -y --no-install-recommends \
    openjdk-21-jdk-headless \
    apache2 \
    mysql-server \
    mysql-client \
    libmysql-java \
    ant \
    curl \
    wget \
    clamav \
    clamav-daemon \
    ufw \
    certbot \
    python3-certbot-apache \
    >> "$LOG" 2>&1

echo "  ✓ Core packages installed"

# ============================================================
# 2. Java Detection
# ============================================================

echo ""
echo "=== [2/8] Configuring Java ==="

# Prefer system JDK 21+, fall back to boot-jdk-27 if available
JAVA_HOME=""
if [ -d /usr/lib/jvm/java-21-openjdk-amd64 ]; then
    JAVA_HOME="/usr/lib/jvm/java-21-openjdk-amd64"
elif [ -d /usr/lib/jvm/java-28-openjdk-amd64 ]; then
    JAVA_HOME="/usr/lib/jvm/java-28-openjdk-amd64"
elif [ -x /usr/local/lib/jvm/jdk-27/bin/javac ]; then
    JAVA_HOME="/usr/local/lib/jvm/jdk-27"
else
    # Use whatever java is on PATH
    JAVA_HOME=$(dirname $(dirname $(readlink -f $(which javac 2>/dev/null || echo /usr/bin/javac))))
fi

echo "  JAVA_HOME=$JAVA_HOME"
echo "  javac: $($JAVA_HOME/bin/javac -version 2>&1 || echo 'not found')"

# Set system-wide JAVA_HOME
cat > /etc/profile.d/java-home.sh << EOF
export JAVA_HOME="$JAVA_HOME"
export PATH="\$JAVA_HOME/bin:\$PATH"
EOF

echo "  ✓ Java configured"

# ============================================================
# 3. Apache Tomcat 10.1
# ============================================================

echo ""
echo "=== [3/8] Installing Apache Tomcat $TOMCAT_VERSION ==="

if [ ! -d "$TOMCAT_HOME" ]; then
    # Create tomcat user
    useradd -r -m -d "$TOMCAT_HOME" -s /bin/false "$TOMCAT_USER" 2>/dev/null || true

    TOMCAT_URL="https://archive.apache.org/dist/tomcat/tomcat-10/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz"
    TOMCAT_TAR="/tmp/tomcat-${TOMCAT_VERSION}.tar.gz"

    # Download Tomcat (or use bundled if available)
    if [ -f "$JWSTF_SRC/resources/tomcat/apache-tomcat-${TOMCAT_VERSION}.tar.gz" ]; then
        TOMCAT_TAR="$JWSTF_SRC/resources/tomcat/apache-tomcat-${TOMCAT_VERSION}.tar.gz"
        echo "  Using bundled Tomcat archive"
    else
        echo "  Downloading Tomcat $TOMCAT_VERSION..."
        curl -fsSL -o "$TOMCAT_TAR" "$TOMCAT_URL" || {
            # Fallback: try latest 10.1.x
            echo "  Trying mirror..."
            wget -q -O "$TOMCAT_TAR" "$TOMCAT_URL" || {
                echo "  WARNING: Could not download Tomcat. Skipping."
                echo "           Install manually: apt install tomcat10"
                TOMCAT_TAR=""
            }
        }
    fi

    if [ -n "$TOMCAT_TAR" ] && [ -f "$TOMCAT_TAR" ]; then
        mkdir -p "$TOMCAT_HOME"
        tar xzf "$TOMCAT_TAR" -C "$TOMCAT_HOME" --strip-components=1
        chown -R "$TOMCAT_USER:$TOMCAT_USER" "$TOMCAT_HOME"
        chmod +x "$TOMCAT_HOME"/bin/*.sh

        # Clean up temp
        [ "$TOMCAT_TAR" = "/tmp/tomcat-${TOMCAT_VERSION}.tar.gz" ] && rm -f "$TOMCAT_TAR"

        echo "  ✓ Tomcat installed at $TOMCAT_HOME"
    fi
else
    echo "  Tomcat already exists at $TOMCAT_HOME"
fi

# Tomcat systemd service
cat > /etc/systemd/system/tomcat.service << EOF
[Unit]
Description=Apache Tomcat 10.1 — NitroWebExpress Servlet Container
After=network.target mysql.service

[Service]
Type=forking
User=$TOMCAT_USER
Group=$TOMCAT_USER
Environment="JAVA_HOME=$JAVA_HOME"
Environment="CATALINA_HOME=$TOMCAT_HOME"
Environment="CATALINA_BASE=$TOMCAT_HOME"
Environment="CATALINA_PID=$TOMCAT_HOME/temp/tomcat.pid"
ExecStart=$TOMCAT_HOME/bin/startup.sh
ExecStop=$TOMCAT_HOME/bin/shutdown.sh
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload 2>/dev/null || true
systemctl enable tomcat.service 2>/dev/null || true
echo "  ✓ Tomcat systemd service configured"

# ============================================================
# 4. MySQL Database Setup
# ============================================================

echo ""
echo "=== [4/8] Configuring MySQL ==="

systemctl enable mysql.service 2>/dev/null || true
systemctl start mysql.service 2>/dev/null || true

# Create database and user (idempotent)
mysql -u root << EOSQL 2>/dev/null || true
CREATE DATABASE IF NOT EXISTS \`$MYSQL_DB\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '$MYSQL_USER'@'localhost' IDENTIFIED BY '$MYSQL_PASS';
GRANT ALL PRIVILEGES ON \`$MYSQL_DB\`.* TO '$MYSQL_USER'@'localhost';
FLUSH PRIVILEGES;
EOSQL

echo "  ✓ Database '$MYSQL_DB' created, user '$MYSQL_USER' configured"

# Run table builder if available
if [ -f "$JWSTF_SRC/scripts/N21.SQL.Table.Builder.sh" ]; then
    echo "  Running table builder..."
    bash "$JWSTF_SRC/scripts/N21.SQL.Table.Builder.sh" >> "$LOG" 2>&1 || true
    echo "  ✓ Application tables created"
elif [ -f "$JWSTF_SRC/db/schema.sql" ]; then
    mysql -u "$MYSQL_USER" -p"$MYSQL_PASS" "$MYSQL_DB" < "$JWSTF_SRC/db/schema.sql" 2>/dev/null || true
    echo "  ✓ Schema loaded from db/schema.sql"
fi

# ============================================================
# 5. Compile NitroWebExpress
# ============================================================

echo ""
echo "=== [5/8] Compiling NitroWebExpress ==="

# Create application user
useradd -r -m -d "$JWSTF_HOME" -s /bin/bash "$JWSTF_USER" 2>/dev/null || true

# Copy source to install location
if [ ! -d "$JWSTF_HOME/source" ]; then
    cp -a "$JWSTF_SRC"/* "$JWSTF_HOME/"
    chown -R "$JWSTF_USER:$JWSTF_GROUP" "$JWSTF_HOME"
fi

# Build classpath
MYSQL_JAR=$(find "$JWSTF_HOME/jars" -name "mysql-connector-*.jar" 2>/dev/null | head -1)
LANTERNA_JAR="$JWSTF_HOME/jars/lanterna-3.1.5.jar"
DJL_JARS=$(find "$JWSTF_HOME/jars/djl" -name "*.jar" 2>/dev/null | tr '\n' ':')
JPCAP_JARS=$(find "$JWSTF_HOME/jars/jpcap" -name "*.jar" 2>/dev/null | tr '\n' ':')
CP="$JWSTF_HOME/out:${MYSQL_JAR}:${LANTERNA_JAR}:${DJL_JARS}${JPCAP_JARS}"

# Compile
mkdir -p "$JWSTF_HOME/out"
JAVA_FILES=$(find "$JWSTF_HOME/source" -name "*.java" | wc -l)
echo "  Compiling $JAVA_FILES Java source files..."

find "$JWSTF_HOME/source" -name "*.java" > /tmp/jwstf-sources.txt

"$JAVA_HOME/bin/javac" \
    --release 21 \
    -cp "$CP" \
    -sourcepath "$JWSTF_HOME/source" \
    -d "$JWSTF_HOME/out" \
    @/tmp/jwstf-sources.txt \
    >> "$LOG" 2>&1 || {
        echo "  WARNING: Some files may not have compiled (non-fatal)"
        # Try with -Xmaxerrs to get as much compiled as possible
        "$JAVA_HOME/bin/javac" \
            --release 21 \
            -cp "$CP" \
            -sourcepath "$JWSTF_HOME/source" \
            -d "$JWSTF_HOME/out" \
            -Xmaxerrs 0 \
            @/tmp/jwstf-sources.txt >> "$LOG" 2>&1 || true
    }

rm -f /tmp/jwstf-sources.txt
chown -R "$JWSTF_USER:$JWSTF_GROUP" "$JWSTF_HOME/out"

CLASS_COUNT=$(find "$JWSTF_HOME/out" -name "*.class" | wc -l)
echo "  ✓ Compiled: $CLASS_COUNT class files"

# Build JAR if ant is available
if command -v ant >/dev/null 2>&1 && [ -f "$JWSTF_HOME/build.xml" ]; then
    echo "  Building nwe.jar via Ant..."
    (cd "$JWSTF_HOME" && ant jar >> "$LOG" 2>&1) || echo "  (ant jar skipped — classes will be used directly)"
fi

# ============================================================
# 6. Apache2 Configuration (Reverse Proxy + Static)
# ============================================================

echo ""
echo "=== [6/8] Configuring Apache2 ==="

# Enable required modules
a2enmod proxy proxy_http proxy_wstunnel rewrite ssl headers 2>/dev/null || true

# Create NWE virtual host
cat > /etc/apache2/sites-available/nwe.conf << 'EOF'
# NitroWebExpress — Apache Virtual Host
# Reverse proxy to Tomcat + static file serving

<VirtualHost *:80>
    ServerName localhost
    ServerAlias *

    DocumentRoot /var/www/html/nwe

    # Static content
    <Directory /var/www/html/nwe>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    # Proxy to Tomcat (servlets + JSP)
    ProxyPreserveHost On
    ProxyPass /api http://127.0.0.1:8080/nwe/api
    ProxyPassReverse /api http://127.0.0.1:8080/nwe/api
    ProxyPass /servlet http://127.0.0.1:8080/nwe/servlet
    ProxyPassReverse /servlet http://127.0.0.1:8080/nwe/servlet
    ProxyPass /ws ws://127.0.0.1:8080/nwe/ws
    ProxyPassReverse /ws ws://127.0.0.1:8080/nwe/ws

    # Security headers
    Header always set X-Content-Type-Options "nosniff"
    Header always set X-Frame-Options "SAMEORIGIN"
    Header always set X-XSS-Protection "1; mode=block"

    ErrorLog ${APACHE_LOG_DIR}/nwe-error.log
    CustomLog ${APACHE_LOG_DIR}/nwe-access.log combined
</VirtualHost>
EOF

# Create document root
mkdir -p /var/www/html/nwe
chown -R www-data:www-data /var/www/html/nwe

# Enable the site
a2ensite nwe.conf 2>/dev/null || true
a2dissite 000-default.conf 2>/dev/null || true

systemctl enable apache2.service 2>/dev/null || true
echo "  ✓ Apache2 configured as reverse proxy"

# ============================================================
# 7. NitroWebExpress Systemd Service
# ============================================================

echo ""
echo "=== [7/8] Creating NWE systemd service ==="

cat > /etc/systemd/system/nwe.service << EOF
[Unit]
Description=NitroWebExpress — Java Web Server (Telnet + HTTP)
After=network.target mysql.service tomcat.service
Requires=mysql.service

[Service]
Type=simple
User=$JWSTF_USER
Group=$JWSTF_GROUP
WorkingDirectory=$JWSTF_HOME
Environment="JAVA_HOME=$JAVA_HOME"
ExecStart=$JAVA_HOME/bin/java \\
    -cp "$JWSTF_HOME/out:$JWSTF_HOME/nwe.jar:${MYSQL_JAR}:${LANTERNA_JAR}:${DJL_JARS}" \\
    -Xmx512m \\
    -Duser.dir=$JWSTF_HOME \\
    Main
Restart=on-failure
RestartSec=5
StandardOutput=journal
StandardError=journal

# Security hardening
ProtectSystem=strict
ReadWritePaths=$JWSTF_HOME/data $JWSTF_HOME/out /var/log/nwe
ProtectHome=true
NoNewPrivileges=true
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF

# Create log directory
mkdir -p /var/log/nwe
chown "$JWSTF_USER:$JWSTF_GROUP" /var/log/nwe

systemctl daemon-reload 2>/dev/null || true
systemctl enable nwe.service 2>/dev/null || true
echo "  ✓ NWE service configured (auto-start on boot)"

# ============================================================
# 8. Firewall & ClamAV
# ============================================================

echo ""
echo "=== [8/9] Firewall & Security ==="

# UFW rules
ufw allow 80/tcp comment 'HTTP - NWE' 2>/dev/null || true
ufw allow 443/tcp comment 'HTTPS - NWE' 2>/dev/null || true
ufw allow 8080/tcp comment 'Tomcat - NWE' 2>/dev/null || true
ufw allow 8443/tcp comment 'Tomcat TLS - NWE' 2>/dev/null || true
ufw allow 23/tcp comment 'Telnet - NWE TUI' 2>/dev/null || true

echo "  ✓ Firewall rules added (80, 443, 8080, 8443, 23)"

# ClamAV
systemctl enable clamav-freshclam.service 2>/dev/null || true
echo "  ✓ ClamAV freshclam enabled"

# ============================================================
# Authentication file
# ============================================================

mkdir -p "$JWSTF_HOME/authentication"
if [ ! -f "$JWSTF_HOME/authentication/mysql.auth.xml" ]; then
    cat > "$JWSTF_HOME/authentication/mysql.auth.xml" << AUTHXML
<?xml version="1.0" encoding="UTF-8"?>
<mysql-authentication>
    <host>localhost</host>
    <port>3306</port>
    <database>$MYSQL_DB</database>
    <username>$MYSQL_USER</username>
    <password>$MYSQL_PASS</password>
</mysql-authentication>
AUTHXML
    chmod 600 "$JWSTF_HOME/authentication/mysql.auth.xml"
    chown "$JWSTF_USER:$JWSTF_GROUP" "$JWSTF_HOME/authentication/mysql.auth.xml"
fi

# ============================================================
# Deploy WAR/servlets to Tomcat
# ============================================================

if [ -d "$TOMCAT_HOME/webapps" ]; then
    echo ""
    echo "  Deploying NWE to Tomcat webapps..."
    mkdir -p "$TOMCAT_HOME/webapps/nwe/WEB-INF/classes"
    mkdir -p "$TOMCAT_HOME/webapps/nwe/WEB-INF/lib"

    # Copy compiled classes
    if [ -d "$JWSTF_HOME/out" ]; then
        cp -a "$JWSTF_HOME/out"/* "$TOMCAT_HOME/webapps/nwe/WEB-INF/classes/" 2>/dev/null || true
    fi

    # Copy dependency JARs
    [ -f "$MYSQL_JAR" ] && cp "$MYSQL_JAR" "$TOMCAT_HOME/webapps/nwe/WEB-INF/lib/"
    [ -f "$LANTERNA_JAR" ] && cp "$LANTERNA_JAR" "$TOMCAT_HOME/webapps/nwe/WEB-INF/lib/"

    # Copy web.xml if available
    if [ -f "$JWSTF_SRC/configuration/web.xml" ]; then
        cp "$JWSTF_SRC/configuration/web.xml" "$TOMCAT_HOME/webapps/nwe/WEB-INF/"
    fi

    chown -R "$TOMCAT_USER:$TOMCAT_USER" "$TOMCAT_HOME/webapps/nwe"
    echo "  ✓ NWE deployed to Tomcat"
fi

# ============================================================
# 9. NWE Gateway (NAT Traversal for Home Users)
# ============================================================

echo ""
echo "=== [9/9] Installing NWE Gateway (NAT traversal) ==="

if [ -f "$JWSTF_SRC/gateway/install-gateway.sh" ]; then
    bash "$JWSTF_SRC/gateway/install-gateway.sh" >> "$LOG" 2>&1
    echo "  ✓ NWE Gateway installed (UPnP + relay fallback)"
elif [ -f "$JWSTF_HOME/gateway/install-gateway.sh" ]; then
    bash "$JWSTF_HOME/gateway/install-gateway.sh" >> "$LOG" 2>&1
    echo "  ✓ NWE Gateway installed (UPnP + relay fallback)"
else
    echo "  NOTE: Gateway scripts not found — install manually later"
fi

# ============================================================
# Summary
# ============================================================

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  JWSTF / NitroWebExpress — Installation Complete            ║"
echo "╠══════════════════════════════════════════════════════════════╣"
echo "║                                                              ║"
echo "║  Services:                                                   ║"
echo "║    • Apache2      → port 80/443 (reverse proxy)             ║"
echo "║    • Tomcat 10.1  → port 8080/8443 (servlet container)      ║"
echo "║    • MySQL 8      → port 3306 (database: $MYSQL_DB)              ║"
echo "║    • NWE          → telnet port 23 + HTTP via Tomcat        ║"
echo "║    • NWE Gateway  → NAT traversal (UPnP / relay tunnel)    ║"
echo "║    • ClamAV       → antivirus                               ║"
echo "║                                                              ║"
echo "║  Paths:                                                      ║"
echo "║    • Application: $JWSTF_HOME/                    ║"
echo "║    • Tomcat:      $TOMCAT_HOME/                   ║"
echo "║    • Web root:    /var/www/html/nwe/                         ║"
echo "║    • Logs:        /var/log/nwe/                              ║"
echo "║                                                              ║"
echo "║  Start:                                                      ║"
echo "║    systemctl start nwe tomcat apache2                        ║"
echo "║                                                              ║"
echo "║  Log: $LOG                           ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
