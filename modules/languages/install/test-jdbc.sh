#!/usr/bin/env bash
# Languages — JDBC Connectivity Test
# Usage: bash install/test-jdbc.sh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MOD_ROOT="$(dirname "$SCRIPT_DIR")"
NWE_ROOT="$(cd "$MOD_ROOT/../.." && pwd)"
DB_PROPS="$MOD_ROOT/servlets/servlet/src/main/webapp/WEB-INF/db.properties"
TMP_DIR="/tmp/languages-jdbc-test"

echo "═══════════════════════════════════════════════════════════════"
echo " Languages — JDBC Connectivity Test"
echo "═══════════════════════════════════════════════════════════════"

echo ""
echo "[1] Locating MySQL connector JAR..."
MYSQL_JAR=$(find \
  "$NWE_ROOT/modules/Brarner.M.Alete/jars" \
  "$NWE_ROOT/jars/mysql" \
  -name "mysql-connector-j-*.jar" 2>/dev/null | head -1)
if [ -z "$MYSQL_JAR" ]; then
    echo "    [FAIL] mysql-connector-j-*.jar not found under $NWE_ROOT"
    exit 1
fi
echo "    [OK] $(basename "$MYSQL_JAR")"

echo ""
echo "[2] Reading db.properties..."
if [ ! -f "$DB_PROPS" ]; then
    echo "    [FAIL] Not found: $DB_PROPS"
    exit 1
fi
DB_URL=$(grep '^db.url=' "$DB_PROPS" | cut -d= -f2-)
DB_USER=$(grep '^db.user=' "$DB_PROPS" | cut -d= -f2-)
DB_HOST=$(echo "$DB_URL" | sed -n 's|.*://\([^:/]*\).*|\1|p'); DB_HOST="${DB_HOST:-127.0.0.1}"
DB_PORT=$(echo "$DB_URL" | sed -n 's|.*:\([0-9]*\)/.*|\1|p'); DB_PORT="${DB_PORT:-3306}"
echo "    user=$DB_USER  host=$DB_HOST:$DB_PORT"

echo ""
echo "[3] MySQL TCP reachability..."
if timeout 2 bash -c "echo >/dev/tcp/$DB_HOST/$DB_PORT" 2>/dev/null; then
    echo "    [OK] $DB_HOST:$DB_PORT reachable"
else
    echo "    [FAIL] Cannot reach $DB_HOST:$DB_PORT — is MySQL running?"
    echo "           Fix: sudo systemctl start mysql"
    exit 1
fi

echo ""
echo "[4] JDBC connection test..."
mkdir -p "$TMP_DIR"
cat > "$TMP_DIR/TestJdbc.java" <<'JAVA'
import java.sql.*;
import java.util.Properties;
import java.io.*;
public class TestJdbc {
    public static void main(String[] args) throws Exception {
        Properties p = new Properties();
        p.load(new FileInputStream(args[0]));
        String url = p.getProperty("db.url");
        String user = p.getProperty("db.user");
        String pass = p.getProperty("db.password", "");
        Class.forName("com.mysql.cj.jdbc.Driver");
        System.out.println("    [*] Connecting: " + url);
        Connection conn = DriverManager.getConnection(url, user, pass);
        DatabaseMetaData md = conn.getMetaData();
        System.out.println("    [OK] " + md.getDatabaseProductName() + " " + md.getDatabaseProductVersion());
        Statement st = conn.createStatement();
        ResultSet rs = st.executeQuery("SELECT @@datadir, @@hostname, @@port");
        if (rs.next()) {
            System.out.println("    [*] datadir=" + rs.getString(1) + "  host=" + rs.getString(2) + "  port=" + rs.getInt(3));
        }
        rs.close();
        rs = st.executeQuery("SELECT 1");
        rs.next();
        System.out.println("    [OK] SELECT 1 = " + rs.getInt(1));
        rs.close();
        rs = st.executeQuery("SHOW DATABASES");
        StringBuilder dbs = new StringBuilder(); int n = 0;
        while (rs.next()) { dbs.append(rs.getString(1)).append(" "); n++; }
        System.out.println("    [*] Databases (" + n + "): " + dbs.toString().trim());
        rs.close(); st.close(); conn.close();
        System.out.println("    [OK] Connection closed cleanly");
        System.out.println("\n═══ JDBC TEST PASSED ═══");
    }
}
JAVA
javac -cp "$MYSQL_JAR" "$TMP_DIR/TestJdbc.java" -d "$TMP_DIR"
java -cp "$TMP_DIR:$MYSQL_JAR" TestJdbc "$DB_PROPS"
EXIT=$?
rm -rf "$TMP_DIR"

echo ""
echo "═══════════════════════════════════════════════════════════════"
[ $EXIT -eq 0 ] && echo " Result: ALL CHECKS PASSED" || echo " Result: FAILED (exit $EXIT)"
echo "═══════════════════════════════════════════════════════════════"
exit $EXIT
