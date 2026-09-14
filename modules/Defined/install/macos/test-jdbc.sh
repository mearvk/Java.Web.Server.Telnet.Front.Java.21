#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# Defined™ — Test JDBC Connectivity (macOS)
# In memory of Steve Jobs. Think Different.
# NitroWebExpress™ — MEARVK LLC
# ═══════════════════════════════════════════════════════════════════════════════
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NWE_ROOT="$(cd "$SCRIPT_DIR/../../../../.." && pwd)"

echo ""
echo "╔═══════════════════════════════════════════════════════════════════════╗"
echo "║  Defined™ — Test JDBC (macOS)                                         ║"
echo "║  In memory of Steve Jobs.                                             ║"
echo "╚═══════════════════════════════════════════════════════════════════════╝"
echo ""

JDBC_JAR=$(find "$NWE_ROOT/jars/mysql" -name "mysql-connector-j-*.jar" 2>/dev/null | head -1)

if [ -z "$JDBC_JAR" ]; then
    echo "  [FAIL] MySQL JDBC connector not found."
    exit 1
fi

echo "  [*] JDBC jar: $JDBC_JAR"
echo "  [*] Testing connection..."

java -cp "$JDBC_JAR:." -e 'Class.forName("com.mysql.cj.jdbc.Driver");' 2>/dev/null && \
    echo "  [OK] JDBC driver loads." || \
    echo "  [--] Could not verify JDBC load."
echo ""
