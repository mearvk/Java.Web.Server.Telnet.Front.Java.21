#!/bin/bash
# NCSU™ — Test Local (macOS)
set -e
echo "[*] Testing NCSU module..."
echo ""

# Test backend
echo -n "  Backend (port 49217): "
if timeout 2 bash -c "echo QUIT | nc localhost 49217" 2>/dev/null | grep -q "NCSU"; then
    echo "✓ UP"
else
    echo "✗ DOWN"
fi

# Test frontend
echo -n "  Frontend (HTTP):      "
HTTP=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/california-ncsu/ 2>/dev/null || echo "000")
if [ "$HTTP" = "200" ] || [ "$HTTP" = "302" ]; then
    echo "✓ HTTP $HTTP"
else
    echo "✗ HTTP $HTTP"
fi

# Test database
echo -n "  Database (nwe_ncsu):  "
if mysql -u root -e "USE nwe_ncsu; SELECT 1;" >/dev/null 2>&1; then
    echo "✓ OK"
else
    echo "✗ FAIL"
fi

echo ""
echo "[OK] Test complete."
