<%@ page contentType="text/plain;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.Properties, java.io.InputStream" %>
<%
/*
 * test-db.jsp — JSP Database Connectivity Test
 *
 * Deploy to webapp root alongside the other JSP pages.
 * Access: http://localhost:8080/brarner.m.alete/test-db.jsp
 *
 * Returns plain text diagnostics showing whether the JSP can:
 *   1. Find and read WEB-INF/db.properties
 *   2. Load the JDBC driver class
 *   3. Open a connection to MySQL
 *   4. Execute a query
 *   5. Find the animalia table
 */

StringBuilder log = new StringBuilder();
log.append("═══════════════════════════════════════════\n");
log.append(" BMA JSP Database Connectivity Test\n");
log.append("═══════════════════════════════════════════\n\n");

// Step 1: Read db.properties
Properties dbProps = new Properties();
InputStream dbIn = application.getResourceAsStream("/WEB-INF/db.properties");
if (dbIn == null) {
    log.append("[FAIL] WEB-INF/db.properties NOT FOUND\n");
    log.append("       The file must exist at:\n");
    log.append("       <tomcat>/webapps/brarner.m.alete/WEB-INF/db.properties\n");
    out.print(log.toString());
    return;
}
dbProps.load(dbIn);
dbIn.close();

String driver = dbProps.getProperty("db.driver", "com.mysql.cj.jdbc.Driver");
String url = dbProps.getProperty("db.url", "");
String user = dbProps.getProperty("db.user", "");
String pass = dbProps.getProperty("db.password", "");

log.append("[OK]   db.properties loaded\n");
log.append("       driver:   " + driver + "\n");
log.append("       url:      " + url + "\n");
log.append("       user:     " + user + "\n");
log.append("       password: " + (pass.isEmpty() ? "(empty)" : "****") + "\n\n");

// Step 2: Load driver
try {
    Class.forName(driver);
    log.append("[OK]   Driver loaded: " + driver + "\n");
} catch (ClassNotFoundException e) {
    log.append("[FAIL] Driver class not found: " + driver + "\n");
    log.append("       Ensure mysql-connector-j-*.jar is in WEB-INF/lib/\n");
    log.append("       Error: " + e.getMessage() + "\n");
    out.print(log.toString());
    return;
}

// Step 3: Connect
Connection conn = null;
try {
    conn = DriverManager.getConnection(url, user, pass);
    DatabaseMetaData md = conn.getMetaData();
    log.append("[OK]   Connected: " + md.getDatabaseProductName() + " " + md.getDatabaseProductVersion() + "\n");
} catch (SQLException e) {
    log.append("[FAIL] Connection failed\n");
    log.append("       URL:   " + url + "\n");
    log.append("       User:  " + user + "\n");
    log.append("       Error: " + e.getMessage() + "\n");
    log.append("       SQLState: " + e.getSQLState() + "\n");
    log.append("       ErrorCode: " + e.getErrorCode() + "\n\n");
    log.append("Troubleshooting:\n");
    log.append("  - Is MySQL running? sudo systemctl status mysql\n");
    log.append("  - Can the user connect? mysql -u" + user + " -p -h localhost\n");
    log.append("  - Does the database exist? SHOW DATABASES;\n");
    log.append("  - Grant access: GRANT ALL ON BrarnerScience.* TO '" + user + "'@'localhost';\n");
    out.print(log.toString());
    return;
}

// Step 4: Execute query
try {
    Statement stmt = conn.createStatement();
    ResultSet rs = stmt.executeQuery("SELECT 1 AS test_col");
    if (rs.next()) {
        log.append("[OK]   Query executed: SELECT 1 = " + rs.getInt(1) + "\n");
    }
    rs.close();
    stmt.close();
} catch (SQLException e) {
    log.append("[FAIL] Query failed: " + e.getMessage() + "\n");
}

// Step 5: Check animalia table
try {
    ResultSet tables = conn.getMetaData().getTables(null, null, "animalia", null);
    if (tables.next()) {
        log.append("[OK]   Table 'animalia' exists\n");

        // Count rows
        Statement stmt = conn.createStatement();
        ResultSet rs = stmt.executeQuery("SELECT COUNT(*) FROM animalia");
        if (rs.next()) log.append("       Rows: " + rs.getInt(1) + "\n");
        rs.close();
        stmt.close();
    } else {
        log.append("[WARN] Table 'animalia' NOT FOUND\n");
        log.append("       species.jsp will show empty results\n");
        log.append("       Run: bash install/run_create_science_db.sh\n");
    }
    tables.close();
} catch (SQLException e) {
    log.append("[WARN] Table check error: " + e.getMessage() + "\n");
}

conn.close();
log.append("\n[OK]   Connection closed cleanly\n");
log.append("\n═══════════════════════════════════════════\n");
log.append(" JSP DB TEST PASSED\n");
log.append(" species.jsp should render database content.\n");
log.append("═══════════════════════════════════════════\n");

out.print(log.toString());
%>
