#!/usr/bin/env bash
# Brarner.M.Alete™ — Download JARs (macOS)
# Usage: bash install/macos/download-jars.sh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BMA_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
JARS_DIR="$BMA_ROOT/jars"
MAVEN="https://repo1.maven.org/maven2"

echo "═══════════════════════════════════════════════════════════════"
echo " Brarner.M.Alete™ — JAR Downloader (macOS)"
echo "═══════════════════════════════════════════════════════════════"

mkdir -p "$JARS_DIR"
cd "$JARS_DIR"

download() {
    local url="$1" file="$(basename "$1")"
    [ -f "$file" ] && echo "  [skip] $file" && return
    echo "  [get]  $file"
    curl -sLO "$url"
}

download "$MAVEN/jakarta/servlet/jakarta.servlet-api/6.1.0/jakarta.servlet-api-6.1.0.jar"
download "$MAVEN/jakarta/annotation/jakarta.annotation-api/3.0.0/jakarta.annotation-api-3.0.0.jar"
download "$MAVEN/jakarta/servlet/jsp/jakarta.servlet.jsp-api/4.0.0/jakarta.servlet.jsp-api-4.0.0.jar"
download "$MAVEN/jakarta/el/jakarta.el-api/6.0.1/jakarta.el-api-6.0.1.jar"
download "$MAVEN/com/mysql/mysql-connector-j/8.3.0/mysql-connector-j-8.3.0.jar"
download "$MAVEN/org/apache/tomcat/embed/tomcat-embed-core/11.0.2/tomcat-embed-core-11.0.2.jar"
download "$MAVEN/org/apache/tomcat/embed/tomcat-embed-jasper/11.0.2/tomcat-embed-jasper-11.0.2.jar"
download "$MAVEN/org/apache/tomcat/embed/tomcat-embed-el/11.0.2/tomcat-embed-el-11.0.2.jar"
download "$MAVEN/org/eclipse/jdt/ecj/3.37.0/ecj-3.37.0.jar"

echo ""
echo "[✓] All JARs in: $JARS_DIR"
echo "═══════════════════════════════════════════════════════════════"
