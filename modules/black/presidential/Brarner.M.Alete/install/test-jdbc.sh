#!/bin/bash
# test-jdbc.sh — Verifies JDBC connectivity and MySQL location
# Checks: where MySQL data lives, that config matches, and JDBC works.
# Usage: bash install/test-jdbc.sh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BMA_ROOT="$(dirname "$SCRIPT_DIR")"
NWE_ROOT="$(cd "$BMA_ROOT/../../../.." 2>/dev/null && pwd || cd "$BMA_ROOT/../../.." 2>/dev/null && pwd)"
DB_PROPS="$BMA_ROOT/servlets/servlet/src/main/webapp/WEB-INF/db.properties"
AUTH_XML="$NWE_ROOT/authentication/mysql.auth.xml"
LIB_DIR="$BMA_ROOT/lib"
TMP_DIR="/tmp/bma-jdbc-test"

echo "═══════════════════════════════════════════════════════════════"
echo " Brarner.M.Alete™ — JDBC & MySQL Location Test"
echo "═══════════════════════════════════════════════════════════════"

# ── 1. Detect MySQL data location ────────────────────────────────────────────
echo ""
echo "[1] MySQL data location..."

MYSQL_DATADIR=""
MYSQL_ON_BLOCK="false"
MYSQL_CONF_FILE=""

# Check config file
for conf in /etc/mysql/mysql.conf.d/mysqld.cnf /etc/mysql/my.cnf /etc/my.cnf; do
    if [ -f "$conf" ]; then
        MYSQL_CONF_FILE="$conf"
        MYSQL_DATADIR=$(grep -E "^datadir" "$conf" 2>/dev/null | awk -F= '{print $2}' | tr -d ' ')
        break
    fi
done

# Check symlink
if [ -z "$MYSQL_DATADIR" ] && [ -L /var/lib/mysql ]; then
    MYSQL_DATADIR=$(readlink -f /var/lib/mysql)
elif [ -z "$MYSQL_DATADIR" ]; then
    MYSQL_DATADIR="/var/lib/mysql"
fi

# Determine storage type
case "$MYSQL_DATADIR" in
    /mnt/blockstorage*) MYSQL_ON_BLOCK="true" ;;
esac

echo "    Config file:   ${MYSQL_CONF_FILE:-not found}"
echo "    Data directory: $MYSQL_DATADIR"
echo "    On block storage: $MYSQL_ON_BLOCK"

if [ -L /var/lib/mysql ]; then
    echo "    Symlink: /var/lib/mysql → $(readlink -f /var/lib/mysql)"
fi

# Check block storage mount
if mountpoint -q /mnt/blockstorage 2>/dev/null; then
    echo "    Block storage: MOUNTED"
    df -h /mnt/blockstorage | tail -1 | awk '{print "      Size:", $2, " Used:", $3, " Avail:", $4, " ("$5")"}'
else
    echo "    Block storage: NOT MOUNTED"
    if [ "$MYSQL_ON_BLOCK" = "true" ]; then
        echo "    [FAIL] MySQL configured for block storage but /mnt/blockstorage not mounted!"
    fi
fi

# Verify datadir actually exists and has data
if [ -d "$MYSQL_DATADIR" ]; then
    DB_COUNT=$(find "$MYSQL_DATADIR" -maxdepth 1 -type d | wc -l)
    TOTAL_SIZE=$(du -sh "$MYSQL_DATADIR" 2>/dev/null | awk '{print $1}')
    echo "    Contents: $((DB_COUNT - 1)) databases, $TOTAL_SIZE total"
    echo "    [OK] Data directory exists and has content"
else
    echo "    [FAIL] Data directory does not exist: $MYSQL_DATADIR"
fi

# ── 2. Check NWE config alignment ────────────────────────────────────────────
echo ""
echo "[2] NWE configuration alignment..."

# Read mysql.auth.xml
if [ -f "$AUTH_XML" ]; then
    AUTH_HOST=$(grep -oP '(?<=<host>)[^<]+' "$AUTH_XML")
    AUTH_PORT=$(grep -oP '(?<=<port>)[^<]+' "$AUTH_XML")
    AUTH_USER=$(grep -oP '(?<=<username>)[^<]+' "$AUTH_XML")
    echo "    mysql.auth.xml: user=$AUTH_USER host=$AUTH_HOST:$AUTH_PORT"
    echo "    [OK] NWE auth config found"
else
    echo "    [WARN] mysql.auth.xml not found at $AUTH_XML"
    AUTH_HOST="localhost"
    AUTH_PORT="3306"
fi

# Read db.properties
if [ -f "$DB_PROPS" ]; then
    DB_URL=$(grep '^db.url=' "$DB_PROPS" | cut -d= -f2-)
    DB_USER=$(grep '^db.user=' "$DB_PROPS" | cut -d= -f2-)
    DB_PASS=$(grep '^db.password=' "$DB_PROPS" | cut -d= -f2-)
    DB_HOST=$(echo "$DB_URL" | sed -n 's|.*://\([^:/]*\).*|\1|p')
    DB_PORT=$(echo "$DB_URL" | sed -n 's|.*:\([0-9]*\)/.*|\1|p')
    DB_NAME=$(echo "$DB_URL" | sed -n 's|.*/\([^?]*\).*|\1|p')
    DB_HOST="${DB_HOST:-localhost}"
    DB_PORT="${DB_PORT:-3306}"
    echo "    db.properties:  user=$DB_USER host=$DB_HOST:$DB_PORT db=$DB_NAME"
    echo "    [OK] db.properties found"
else
    echo "    [FAIL] db.properties not found: $DB_PROPS"
    echo "           Run: bash install/set-db-credentials.sh"
    exit 1
fi

# Check configs point to same MySQL instance
if [ "$AUTH_HOST" = "$DB_HOST" ] && [ "$AUTH_PORT" = "$DB_PORT" ]; then
    echo "    [OK] NWE auth and BMA db.properties point to same MySQL ($DB_HOST:$DB_PORT)"
else
    echo "    [WARN] Config mismatch:"
    echo "           mysql.auth.xml → $AUTH_HOST:$AUTH_PORT"
    echo "           db.properties  → $DB_HOST:$DB_PORT"
fi

# Verify MySQL is actually listening where config says
if timeout 2 bash -c "echo >/dev/tcp/$DB_HOST/$DB_PORT" 2>/dev/null; then
    echo "    [OK] MySQL reachable at $DB_HOST:$DB_PORT"
else
    echo "    [FAIL] Cannot connect to $DB_HOST:$DB_PORT — MySQL not running?"
    echo "           Check: systemctl status mysql"
    exit 1
fi

# ── 3. JDBC connectivity test ─────────────────────────────────────────────────
echo ""
echo "[3] JDBC connectivity test..."

# Find MySQL connector JAR
MYSQL_JAR=$(find "$LIB_DIR" "$BMA_ROOT/jars" -name "mysql-connector-j-*.jar" 2>/dev/null | head -1)
if [ -z "$MYSQL_JAR" ]; then
    MYSQL_JAR=$(find "$NWE_ROOT/jars" -name "mysql-connector-j-*.jar" 2>/dev/null | head -1)
fi
if [ -z "$MYSQL_JAR" ]; then
    echo "    [FAIL] MySQL connector JAR not found"
    echo "           Run: bash install/download-jars.sh"
    exit 1
fi
echo "    JAR: $(basename "$MYSQL_JAR")"

# Create test class
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

        String url = p.getProperty("db.url");
        String user = p.getProperty("db.user");
        String pass = p.getProperty("db.password", "");

        Class.forName("com.mysql.cj.jdbc.Driver");
        System.out.println("    [*] Connecting: " + url);

        Connection conn = DriverManager.getConnection(url, user, pass);
        DatabaseMetaData md = conn.getMetaData();
        System.out.println("    [OK] Connected: " + md.getDatabaseProductName() + " " + md.getDatabaseProductVersion());

        // Show MySQL datadir from server
        Statement st = conn.createStatement();
        ResultSet rs = st.executeQuery("SELECT @@datadir AS datadir, @@hostname AS hostname, @@port AS port");
        if (rs.next()) {
            System.out.println("    [*] Server datadir: " + rs.getString("datadir"));
            System.out.println("    [*] Server hostname: " + rs.getString("hostname"));
            System.out.println("    [*] Server port: " + rs.getInt("port"));

            String serverDatadir = rs.getString("datadir");
            if (serverDatadir.startsWith("/mnt/blockstorage")) {
                System.out.println("    [OK] MySQL data is on BLOCK STORAGE");
            } else {
                System.out.println("    [*] MySQL data is on MAIN DRIVE");
                System.out.println("    [HINT] To free main drive, run: sudo bash scripts/migrate-mysql-to-blockstorage.sh");
            }
        }
        rs.close();

        // Test query
        rs = st.executeQuery("SELECT 1 AS test_col");
        if (rs.next()) {
            System.out.println("    [OK] Query: SELECT 1 = " + rs.getInt(1));
        }
        rs.close();

        // Check BrarnerScience database tables
        rs = conn.getMetaData().getTables(null, null, "animalia", null);
        if (rs.next()) {
            System.out.println("    [OK] Table 'animalia' exists");
        } else {
            System.out.println("    [WARN] Table 'animalia' NOT FOUND — species.jsp will show empty");
        }
        rs.close();

        // Show all databases
        rs = st.executeQuery("SHOW DATABASES");
        StringBuilder dbs = new StringBuilder();
        int count = 0;
        while (rs.next()) { dbs.append(rs.getString(1)).append(" "); count++; }
        System.out.println("    [*] Databases (" + count + "): " + dbs.toString().trim());
        rs.close();

        st.close();
        conn.close();
        System.out.println("    [OK] Connection closed cleanly");
        System.out.println("");
        System.out.println("═══ JDBC TEST PASSED ═══");
    }
}
JAVA

echo "    [*] Compiling test..."
javac -cp "$MYSQL_JAR" "$TMP_DIR/TestJdbc.java" -d "$TMP_DIR"

echo ""
java -cp "$TMP_DIR:$MYSQL_JAR" TestJdbc "$DB_PROPS"
EXIT=$?

rm -rf "$TMP_DIR"

echo ""
echo "═══════════════════════════════════════════════════════════════"
if [ $EXIT -eq 0 ]; then
    echo " Result: ALL CHECKS PASSED"
else
    echo " Result: FAILED (exit $EXIT)"
fi
echo "═══════════════════════════════════════════════════════════════"

exit $EXIT
