#!/bin/bash
# scripts/deploy-functions.sh — Shared deployment functions for JSP/EJB modules
# Source from any module deploy-local.sh:
#   source "$NWE_ROOT/scripts/deploy-functions.sh"
#
# Functions:
#   nwe_read_web_servers  — Read Tomcat/Apache settings from nwe-config.xml
#   nwe_validate_tomcat   — Verify Tomcat installation exists
#   nwe_deploy_webapp     — Copy webapp source to Tomcat webapps
#   nwe_install_jdbc      — Find and copy MySQL JDBC connector to WEB-INF/lib
#   nwe_compile_servlets  — Compile servlet Java classes against Tomcat API
#   nwe_validate_webapp   — Check web.xml, JSP files, and lib presence
#   nwe_deploy_module     — All-in-one: validate → deploy → JDBC → compile → validate
#   nwe_progress          — Display a progress bar for long operations

# ═══════════════════════════════════════════════════════════════════════════════
# nwe_read_web_servers — Read web server config from nwe-config.xml
# Sets: NWE_TOMCAT_VERSION, NWE_TOMCAT_HOME, NWE_TOMCAT_TECH_ID,
#       NWE_APACHE_VERSION, NWE_APACHE_ROOT, NWE_APACHE_TECH_ID
# Falls back to defaults if config not found.
# ═══════════════════════════════════════════════════════════════════════════════
nwe_read_web_servers() {
    local NWE_ROOT="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
    local CONFIG="$NWE_ROOT/configuration/nwe-config.xml"

    if [ -f "$CONFIG" ]; then
        local TOMCAT_SECTION
        TOMCAT_SECTION=$(sed -n '/<tomcat>/,/<\/tomcat>/p' "$CONFIG" 2>/dev/null)
        local APACHE_SECTION
        APACHE_SECTION=$(sed -n '/<apache>/,/<\/apache>/p' "$CONFIG" 2>/dev/null)

        NWE_TOMCAT_VERSION=$(echo "$TOMCAT_SECTION" | grep -oP '(?<=<version>)[^<]+' 2>/dev/null)
        NWE_TOMCAT_HOME=$(echo "$TOMCAT_SECTION" | grep -oP '(?<=<install-dir>)[^<]+' 2>/dev/null)
        NWE_TOMCAT_TECH_ID=$(echo "$TOMCAT_SECTION" | grep -oP '(?<=<tech-id>)[^<]+' 2>/dev/null)

        NWE_APACHE_VERSION=$(echo "$APACHE_SECTION" | grep -oP '(?<=<version>)[^<]+' 2>/dev/null)
        NWE_APACHE_ROOT=$(echo "$APACHE_SECTION" | grep -oP '(?<=<install-dir>)[^<]+' 2>/dev/null)
        NWE_APACHE_APP_DIR=$(echo "$APACHE_SECTION" | grep -oP '(?<=<app-subdir>)[^<]+' 2>/dev/null)
        NWE_APACHE_TECH_ID=$(echo "$APACHE_SECTION" | grep -oP '(?<=<tech-id>)[^<]+' 2>/dev/null)
    fi

    # Defaults
    NWE_TOMCAT_VERSION="${NWE_TOMCAT_VERSION:-11.0.2}"
    NWE_TOMCAT_HOME="${NWE_TOMCAT_HOME:-/opt/apache-tomcat-11.0.2}"
    NWE_TOMCAT_TECH_ID="${NWE_TOMCAT_TECH_ID:-MEARVK-LLC-Default}"
    NWE_APACHE_VERSION="${NWE_APACHE_VERSION:-2.4}"
    NWE_APACHE_ROOT="${NWE_APACHE_ROOT:-/var/www/html}"
    NWE_APACHE_APP_DIR="${NWE_APACHE_APP_DIR:-nwe}"
    NWE_APACHE_TECH_ID="${NWE_APACHE_TECH_ID:-MEARVK-LLC-Default}"

    export NWE_TOMCAT_VERSION NWE_TOMCAT_HOME NWE_TOMCAT_TECH_ID
    export NWE_APACHE_VERSION NWE_APACHE_ROOT NWE_APACHE_APP_DIR NWE_APACHE_TECH_ID
}

# ═══════════════════════════════════════════════════════════════════════════════
# nwe_progress — Display a progress bar during a copy/rsync operation
# Args: $1 = source dir, $2 = dest dir, $3 = operation label
# Uses rsync with --progress if available, else cp with file counting
# ═══════════════════════════════════════════════════════════════════════════════
nwe_progress_copy() {
    local SRC="$1" DEST="$2" LABEL="${3:-Copying}"

    # Count total files for progress
    local TOTAL_FILES
    TOTAL_FILES=$(find "$SRC" -type f 2>/dev/null | wc -l)

    if [ "$TOTAL_FILES" -eq 0 ]; then
        echo "  [$LABEL] (empty source)"
        return 0
    fi

    if command -v rsync &>/dev/null; then
        # rsync with progress indicator
        echo -n "  [$LABEL] $TOTAL_FILES files... "
        rsync -a --delete --exclude='db.properties' "$SRC/" "$DEST/" 2>/dev/null
        echo "✓"
    else
        # cp with a simple progress counter
        rm -rf "$DEST"
        mkdir -p "$DEST"

        local COUNT=0
        local LAST_PCT=-1

        # Use cp -r but show progress by counting copied files
        cp -r "$SRC/"* "$DEST/" &
        local CP_PID=$!

        # Show a spinner while cp runs
        local SPINNER=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
        local SPIN_IDX=0
        echo -n "  [$LABEL] $TOTAL_FILES files "
        while kill -0 "$CP_PID" 2>/dev/null; do
            echo -ne "\r  [$LABEL] $TOTAL_FILES files ${SPINNER[$SPIN_IDX]} "
            SPIN_IDX=$(( (SPIN_IDX + 1) % ${#SPINNER[@]} ))
            sleep 0.2
        done
        wait "$CP_PID"
        echo -e "\r  [$LABEL] $TOTAL_FILES files ✓ "
    fi
    return 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# nwe_progress_bar — Print a progress bar inline
# Args: $1 = current, $2 = total, $3 = label (optional)
# ═══════════════════════════════════════════════════════════════════════════════
nwe_progress_bar() {
    local CURRENT="$1" TOTAL="$2" LABEL="${3:-Progress}"
    local WIDTH=30
    local PCT=$((CURRENT * 100 / TOTAL))
    local FILLED=$((CURRENT * WIDTH / TOTAL))
    local EMPTY=$((WIDTH - FILLED))
    printf "\r  [%s] [%s%s] %3d%% (%d/%d)" "$LABEL" \
        "$(printf '█%.0s' $(seq 1 $FILLED 2>/dev/null) 2>/dev/null)" \
        "$(printf '░%.0s' $(seq 1 $EMPTY 2>/dev/null) 2>/dev/null)" \
        "$PCT" "$CURRENT" "$TOTAL"
}

# ═══════════════════════════════════════════════════════════════════════════════
# nwe_download_with_progress — Download a file with a progress bar
# Args: $1 = URL, $2 = output file, $3 = label (optional)
# ═══════════════════════════════════════════════════════════════════════════════
nwe_download_with_progress() {
    local URL="$1" OUTPUT="$2" LABEL="${3:-Downloading}"

    echo -n "  [$LABEL] $(basename "$OUTPUT")... "

    if command -v curl &>/dev/null; then
        curl -# -fL "$URL" -o "$OUTPUT" 2>&1 | tr '\r' '\n' | tail -1
        if [ ${PIPESTATUS[0]} -eq 0 ]; then
            local SIZE
            SIZE=$(du -h "$OUTPUT" 2>/dev/null | cut -f1)
            echo "✓ ($SIZE)"
            return 0
        else
            echo "✗ (download failed)"
            return 1
        fi
    elif command -v wget &>/dev/null; then
        wget --progress=bar:force "$URL" -O "$OUTPUT" 2>&1 | tail -1
        [ -f "$OUTPUT" ] && echo "✓" || echo "✗"
        return ${PIPESTATUS[0]}
    else
        echo "✗ (no curl or wget)"
        return 1
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# nwe_validate_tomcat — Check Tomcat installation
# Args: $1 = TOMCAT_HOME path
# Returns: 0 on success, 1 on failure
# ═══════════════════════════════════════════════════════════════════════════════
nwe_validate_tomcat() {
    local TH="${1:-/opt/apache-tomcat-11.0.2}"
    if [ ! -d "$TH/webapps" ]; then
        echo "[!] Tomcat not found at: $TH"
        echo "    Set CATALINA_HOME or pass path as argument."
        return 1
    fi
    if [ ! -f "$TH/bin/catalina.sh" ]; then
        echo "[!] Tomcat appears incomplete (no bin/catalina.sh): $TH"
        return 1
    fi
    if [ ! -d "$TH/lib" ]; then
        echo "[!] Tomcat lib directory missing: $TH/lib"
        return 1
    fi
    return 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# nwe_deploy_webapp — Copy webapp source tree to Tomcat deploy directory
# Args: $1 = source webapp dir, $2 = deploy dir (will be rm -rf'd and recreated)
# ═══════════════════════════════════════════════════════════════════════════════
nwe_deploy_webapp() {
    local SRC="$1" DEST="$2"
    if [ ! -d "$SRC" ]; then
        echo "[!] Webapp source not found: $SRC"
        return 1
    fi
    mkdir -p "$DEST/WEB-INF/lib" "$DEST/WEB-INF/classes"
    nwe_progress_copy "$SRC" "$DEST" "Deploy"
    echo "[✓] Webapp deployed to $DEST"
    return 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# nwe_ensure_db_properties — Generate db.properties from .nwe-credentials
# Args: $1 = deploy dir (WEB-INF/db.properties will be created here)
#       $2 = database name
#       $3 = NWE project root
# ═══════════════════════════════════════════════════════════════════════════════
nwe_ensure_db_properties() {
    local DEPLOY_DIR="$1" DB_NAME="$2" NWE_ROOT="${3:-}"
    local DB_PROPS="$DEPLOY_DIR/WEB-INF/db.properties"

    # If already exists (from webapp source), leave it alone
    if [ -f "$DB_PROPS" ] && grep -q "db.password=." "$DB_PROPS" 2>/dev/null; then
        # Validate it doesn't have CHANGE_ME placeholder
        if ! grep -q "CHANGE_ME" "$DB_PROPS" 2>/dev/null; then
            return 0
        fi
    fi

    # Source credentials
    local CREDS=""
    [ -n "$NWE_ROOT" ] && [ -f "$NWE_ROOT/.nwe-credentials" ] && CREDS="$NWE_ROOT/.nwe-credentials"
    [ -z "$CREDS" ] && [ -f ".nwe-credentials" ] && CREDS=".nwe-credentials"

    if [ -n "$CREDS" ]; then
        source "$CREDS"
        mkdir -p "$DEPLOY_DIR/WEB-INF"
        cat > "$DB_PROPS" <<EOF
# Auto-generated by deploy-functions.sh from .nwe-credentials
# Do NOT commit this file (it is .gitignored)
db.driver=com.mysql.cj.jdbc.Driver
db.url=jdbc:mysql://${NWE_DB_HOST:-127.0.0.1}:${NWE_DB_PORT:-3306}/${DB_NAME}
db.user=${NWE_DB_USER:-root}
db.password=${NWE_DB_PASS}
EOF
        chmod 600 "$DB_PROPS"
        echo "[✓] db.properties generated from .nwe-credentials"
    else
        echo "[!] No .nwe-credentials found — db.properties may have placeholder password"
        echo "    Run: cp .nwe-credentials.example .nwe-credentials && edit"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# nwe_install_jdbc — Find MySQL JDBC connector and install to WEB-INF/lib
# Args: $1 = deploy dir, $2 = NWE project root
# ═══════════════════════════════════════════════════════════════════════════════
nwe_install_jdbc() {
    local DEPLOY_DIR="$1" NWE_ROOT="$2"
    local TOMCAT_HOME="${3:-/opt/apache-tomcat-11.0.2}"
    local JDBC_JAR=""

    # Search order: project jars → Tomcat lib → system
    JDBC_JAR=$(find "$NWE_ROOT/jars/mysql" -name "mysql-connector-j*.jar" -type f 2>/dev/null | head -1)
    [ -z "$JDBC_JAR" ] && JDBC_JAR=$(find "$TOMCAT_HOME/lib" -name "mysql-connector-j*.jar" -type f 2>/dev/null | head -1)
    [ -z "$JDBC_JAR" ] && JDBC_JAR=$(find /usr/share/java -name "mysql-connector*.jar" -type f 2>/dev/null | head -1)

    if [ -n "$JDBC_JAR" ]; then
        mkdir -p "$DEPLOY_DIR/WEB-INF/lib"
        cp "$JDBC_JAR" "$DEPLOY_DIR/WEB-INF/lib/"
        echo "[✓] JDBC: $(basename "$JDBC_JAR")"
        return 0
    else
        echo "[!] WARNING: MySQL JDBC connector not found"
        echo "    JSP pages with database queries will fail at runtime."
        echo "    Install: cp mysql-connector-j-9.7.0.jar $DEPLOY_DIR/WEB-INF/lib/"
        return 1
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# nwe_compile_servlets — Compile servlet Java classes against Tomcat API
# Args: $1 = Java source dir, $2 = deploy dir, $3 = Tomcat home
# ═══════════════════════════════════════════════════════════════════════════════
nwe_compile_servlets() {
    local JAVA_SRC="$1" DEPLOY_DIR="$2" TOMCAT_HOME="${3:-/opt/apache-tomcat-11.0.2}"

    if ! command -v javac &>/dev/null; then
        echo "[--] javac not found — servlet classes not compiled (JSP still works)"
        return 0
    fi

    if [ ! -d "$JAVA_SRC" ]; then
        echo "[--] No servlet source at $JAVA_SRC — skipping compilation"
        return 0
    fi

    local JAVA_FILES
    JAVA_FILES=$(find "$JAVA_SRC" -name "*.java" 2>/dev/null)
    if [ -z "$JAVA_FILES" ]; then
        echo "[--] No .java files in $JAVA_SRC — skipping compilation"
        return 0
    fi

    # Build classpath: Tomcat servlet API + module WEB-INF/lib
    local SERVLET_API
    SERVLET_API=$(find "$TOMCAT_HOME/lib" -name "servlet-api.jar" -o -name "jakarta.servlet-api*.jar" 2>/dev/null | head -1)
    if [ -z "$SERVLET_API" ]; then
        echo "[!] No servlet-api.jar in $TOMCAT_HOME/lib — cannot compile servlets"
        return 1
    fi

    local CP="$SERVLET_API"
    [ -d "$DEPLOY_DIR/WEB-INF/lib" ] && CP="$CP:$DEPLOY_DIR/WEB-INF/lib/*"

    mkdir -p "$DEPLOY_DIR/WEB-INF/classes"
    if find "$JAVA_SRC" -name "*.java" | xargs javac -cp "$CP" -d "$DEPLOY_DIR/WEB-INF/classes" 2>&1; then
        local CLASS_COUNT
        CLASS_COUNT=$(find "$DEPLOY_DIR/WEB-INF/classes" -name "*.class" 2>/dev/null | wc -l)
        echo "[✓] Servlets compiled: $CLASS_COUNT classes"
        return 0
    else
        echo "[!] Servlet compilation failed (non-fatal — JSP pages still work)"
        return 1
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# nwe_validate_webapp — Post-deploy validation checks
# Args: $1 = deploy dir
# ═══════════════════════════════════════════════════════════════════════════════
nwe_validate_webapp() {
    local DEPLOY_DIR="$1"
    local WARNINGS=0

    # Check web.xml
    if [ ! -f "$DEPLOY_DIR/WEB-INF/web.xml" ]; then
        echo "[!] WARNING: No WEB-INF/web.xml — Tomcat may not load this webapp"
        WARNINGS=$((WARNINGS + 1))
    fi

    # Check JSP count
    local JSP_COUNT
    JSP_COUNT=$(find "$DEPLOY_DIR" -name "*.jsp" 2>/dev/null | wc -l)
    if [ "$JSP_COUNT" -eq 0 ]; then
        # Check for XHTML fallback
        local XHTML_COUNT
        XHTML_COUNT=$(find "$DEPLOY_DIR" -name "*.xhtml" -o -name "*.html" 2>/dev/null | wc -l)
        if [ "$XHTML_COUNT" -eq 0 ]; then
            echo "[!] WARNING: No JSP or HTML files found"
            WARNINGS=$((WARNINGS + 1))
        else
            echo "[✓] HTML/XHTML pages: $XHTML_COUNT (no JSP)"
        fi
    else
        echo "[✓] JSP pages: $JSP_COUNT"
    fi

    # Check JDBC jar in WEB-INF/lib
    local JDBC_IN_LIB
    JDBC_IN_LIB=$(find "$DEPLOY_DIR/WEB-INF/lib" -name "mysql-connector*" 2>/dev/null | wc -l)
    if [ "$JDBC_IN_LIB" -eq 0 ]; then
        echo "[!] WARNING: No JDBC driver in WEB-INF/lib — database features will fail"
        WARNINGS=$((WARNINGS + 1))
    fi

    if [ $WARNINGS -eq 0 ]; then
        echo "[✓] Webapp validation passed"
    fi

    return $WARNINGS
}

# ═══════════════════════════════════════════════════════════════════════════════
# nwe_deploy_module — All-in-one deploy for a standard JSP/servlet module
# Args: $1=module_name, $2=context, $3=webapp_src, $4=java_src, $5=tomcat_home, $6=nwe_root
# ═══════════════════════════════════════════════════════════════════════════════
nwe_deploy_module() {
    local MODULE_NAME="$1"
    local CONTEXT="$2"
    local WEBAPP_SRC="$3"
    local JAVA_SRC="${4:-}"
    local TOMCAT_HOME="${5:-/opt/apache-tomcat-11.0.2}"
    local NWE_ROOT="${6:-}"
    local DEPLOY_DIR="$TOMCAT_HOME/webapps/$CONTEXT"

    echo "[*] Deploying ${MODULE_NAME}™ to $DEPLOY_DIR"

    nwe_validate_tomcat "$TOMCAT_HOME" || return 1
    nwe_deploy_webapp "$WEBAPP_SRC" "$DEPLOY_DIR" || return 1
    nwe_install_jdbc "$DEPLOY_DIR" "$NWE_ROOT" "$TOMCAT_HOME"
    [ -n "$JAVA_SRC" ] && nwe_compile_servlets "$JAVA_SRC" "$DEPLOY_DIR" "$TOMCAT_HOME"
    nwe_validate_webapp "$DEPLOY_DIR"

    echo "[OK] ${MODULE_NAME}™ deployed at /$CONTEXT"
    return 0
}
