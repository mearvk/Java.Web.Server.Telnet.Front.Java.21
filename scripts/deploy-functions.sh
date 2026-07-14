#!/bin/bash
# scripts/deploy-functions.sh — Shared deployment functions for JSP/EJB modules
# Source from any module deploy-local.sh:
#   source "$NWE_ROOT/scripts/deploy-functions.sh"
#
# Functions:
#   nwe_validate_tomcat   — Verify Tomcat installation exists
#   nwe_deploy_webapp     — Copy webapp source to Tomcat webapps
#   nwe_install_jdbc      — Find and copy MySQL JDBC connector to WEB-INF/lib
#   nwe_compile_servlets  — Compile servlet Java classes against Tomcat API
#   nwe_validate_webapp   — Check web.xml, JSP files, and lib presence
#   nwe_deploy_module     — All-in-one: validate → deploy → JDBC → compile → validate

# ═══════════════════════════════════════════════════════════════════════════════
# nwe_validate_tomcat — Check Tomcat installation
# Args: $1 = TOMCAT_HOME path
# Returns: 0 on success, 1 on failure
# ═══════════════════════════════════════════════════════════════════════════════
nwe_validate_tomcat() {
    local TH="${1:-/home/mearvk/tomcat}"
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
    rm -rf "$DEST"
    mkdir -p "$DEST/WEB-INF/lib" "$DEST/WEB-INF/classes"
    cp -r "$SRC/"* "$DEST/"
    echo "[✓] Webapp deployed to $DEST"
    return 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# nwe_install_jdbc — Find MySQL JDBC connector and install to WEB-INF/lib
# Args: $1 = deploy dir, $2 = NWE project root
# ═══════════════════════════════════════════════════════════════════════════════
nwe_install_jdbc() {
    local DEPLOY_DIR="$1" NWE_ROOT="$2"
    local TOMCAT_HOME="${3:-/home/mearvk/tomcat}"
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
    local JAVA_SRC="$1" DEPLOY_DIR="$2" TOMCAT_HOME="${3:-/home/mearvk/tomcat}"

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
    local TOMCAT_HOME="${5:-/home/mearvk/tomcat}"
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
