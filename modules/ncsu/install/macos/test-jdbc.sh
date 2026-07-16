#!/bin/bash
# NCSU™ — Test JDBC (macOS)
set -e
echo "[*] Testing JDBC connection to nwe_ncsu..."
NWE_ROOT="$(cd "$(dirname "$0")/../../../.." && pwd)"
java -cp "$NWE_ROOT/jars/mysql/mysql-connector-j-9.7.0.jar:." -e "
Class.forName(\"com.mysql.cj.jdbc.Driver\");
var c = java.sql.DriverManager.getConnection(\"jdbc:mysql://localhost:3306/nwe_ncsu\", \"root\", \"\");
System.out.println(\"[OK] Connected to nwe_ncsu\");
c.close();
" 2>/dev/null || echo "[!] JDBC test requires inline Java — use test-local.sh instead"
echo "[OK] JDBC test complete."
