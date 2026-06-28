#!/bin/bash
# test-jdbc.sh — Verifies JDBC connectivity using db.properties credentials
# Compiles and runs a minimal Java class that loads the MySQL driver and connects.
# Usage: bash install/test-jdbc.sh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BMA_ROOT="$(dirname "$SCRIPT_DIR")"
DB_PROPS="$BMA_ROOT/servlets/servlet/src/main/webapp/WEB-INF/db.properties"
LIB_DIR="$BMA_ROOT/lib"
TMP_DIR="/tmp/bma-jdbc-test"

echo "═══════════════════════════════════════════════════════════════"
echo " Brarner.M.Alete™ — JDBC Connectivity Test"
echo "═══════════════════════════════════════════════════════════════"

if [ ! -f "$DB_PROPS" ]; then
    echo "[FAIL] db.properties not found: $DB_PROPS"
    echo "       Run: bash install/install.sh"
    exit 1
fi

echo "[*] Reading db.properties..."
DB_DRIVER=$(grep '^db.driver=' "$DB_PROPS" | cut -d= -f2-)
DB_URL=$(grep '^db.url=' "$DB_PROPS" | cut -d= -f2-)
DB_USER=$(grep '^db.user=' "$DB_PROPS" | cut -d= -f2-)
DB_PASS=$(grep '^db.password=' "$DB_PROPS" | cut -d= -f2-)
echo "    driver:   $DB_DRIVER"
echo "    url:      $DB_URL"
echo "    user:     $DB_USER"
echo "    password: $(echo "$DB_PASS" | sed 's/./*/g')"

# Find MySQL connector JAR
MYSQL_JAR=$(ls "$LIB_DIR"/mysql-connector-j-*.jar 2>/dev/null | head -1)
if [ -z "$MYSQL_JAR" ]; then
    MYSQL_JAR=$(find / -name "mysql-connector-j-*.jar" -o -name "mysql-connector-java-*.jar" 2>/dev/null | head -1)
fi
if [ -z "$MYSQL_JAR" ]; then
    echo "[FAIL] MySQL connector JAR not found in $LIB_DIR"
    echo "       Run: bash install/download-jars.sh"
    exit 1
fi
echo "    jar:      $MYSQL_JAR"

# Create test Java source
mkdir -p "$TMP_DIR"
cat > "$TMP_DIR/TestJdbc.java" <<'JAVA'
import java.sql.*;
import java.util.Properties;
import java.io.*;

public class TestJdbc {
    public static void main(String[] args) throws Exception {
        String propsFile = args[0];
        Properties p = new Properties();
        p.load(new FileInputStream(propsFile));

        String driver = p.getProperty("db.driver", "com.mysql.cj.jdbc.Driver");
        String url = p.getProperty("db.url");
        String user = p.getProperty("db.user");
        String pass = p.getProperty("db.password", "");

        System.out.println("[*] Loading driver: " + driver);
        Class.forName(driver);

        System.out.println("[*] Connecting: " + url + " (user=" + user + ")");
        Connection conn = DriverManager.getConnection(url, user, pass);

        DatabaseMetaData md = conn.getMetaData();
        System.out.println("[OK] Connected: " + md.getDatabaseProductName() + " " + md.getDatabaseProductVersion());

        // Test a simple query
        Statement stmt = conn.createStatement();
        ResultSet rs = stmt.executeQuery("SELECT 1 AS test_col");
        if (rs.next()) {
            System.out.println("[OK] Query executed: SELECT 1 = " + rs.getInt(1));
        }
        rs.close();
        stmt.close();

        // Check if animalia table exists
        rs = conn.getMetaData().getTables(null, null, "animalia", null);
        if (rs.next()) {
            System.out.println("[OK] Table 'animalia' exists");
        } else {
            System.out.println("[WARN] Table 'animalia' NOT FOUND — species.jsp will show empty results");
        }
        rs.close();

        conn.close();
        System.out.println("[OK] Connection closed cleanly");
        System.out.println("");
        System.out.println("JDBC TEST PASSED — db.properties credentials work.");
    }
}
JAVA

echo ""
echo "[*] Compiling test class..."
javac -cp "$MYSQL_JAR" "$TMP_DIR/TestJdbc.java" -d "$TMP_DIR"

echo "[*] Running JDBC connection test..."
echo ""
java -cp "$TMP_DIR:$MYSQL_JAR" TestJdbc "$DB_PROPS"
EXIT=$?

rm -rf "$TMP_DIR"
exit $EXIT
