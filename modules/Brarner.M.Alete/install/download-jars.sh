#!/usr/bin/env bash
# Brarner.M.Alete™ — Download JARs Script (Linux/macOS)
# Downloads all required JARs to run the BMA servlet site.
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BMA_ROOT="$(dirname "$SCRIPT_DIR")"
LIB_DIR="$BMA_ROOT/lib"
MAVEN_CENTRAL="https://repo1.maven.org/maven2"

echo "═══════════════════════════════════════════════════════════════"
echo " Brarner.M.Alete™ — JAR Downloader"
echo " Fetching servlet runtime dependencies..."
echo "═══════════════════════════════════════════════════════════════"

mkdir -p "$LIB_DIR"
cd "$LIB_DIR"

download() {
    local url="$1"
    local file="$(basename "$url")"
    if [ -f "$file" ]; then
        echo "  [skip] $file (exists)"
    else
        echo "  [get]  $file"
        curl -sLO "$url"
    fi
}

echo ""
echo "[1/5] Jakarta Servlet API 6.1.0"
download "$MAVEN_CENTRAL/jakarta/servlet/jakarta.servlet-api/6.1.0/jakarta.servlet-api-6.1.0.jar"

echo "[2/5] Jakarta Annotation API 3.0.0"
download "$MAVEN_CENTRAL/jakarta/annotation/jakarta.annotation-api/3.0.0/jakarta.annotation-api-3.0.0.jar"

echo "[3/5] MySQL Connector/J 8.3.0"
download "$MAVEN_CENTRAL/com/mysql/mysql-connector-j/8.3.0/mysql-connector-j-8.3.0.jar"

echo "[4/5] Apache Tomcat Embed Core 11.0.2 (embedded runner)"
download "$MAVEN_CENTRAL/org/apache/tomcat/embed/tomcat-embed-core/11.0.2/tomcat-embed-core-11.0.2.jar"

echo "[5/5] Apache Tomcat Embed Jasper 11.0.2 (JSP support)"
download "$MAVEN_CENTRAL/org/apache/tomcat/embed/tomcat-embed-jasper/11.0.2/tomcat-embed-jasper-11.0.2.jar"

echo ""
echo "[✓] All JARs downloaded to: $LIB_DIR"
ls -lh "$LIB_DIR"/*.jar 2>/dev/null | awk '{print "    " $NF " (" $5 ")"}'
echo "═══════════════════════════════════════════════════════════════"
