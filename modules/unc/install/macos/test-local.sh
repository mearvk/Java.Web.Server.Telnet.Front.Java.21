#!/bin/bash
# UNC Chapel Hill™ — Test Local (macOS)
set -e
echo "[*] Testing UNC Chapel Hill module..."
echo ""
echo -n "  Backend (port 49218): "
if timeout 2 bash -c "echo QUIT | nc localhost 49218" 2>/dev/null | grep -q "UNC"; then
    echo "✓ UP"
else
    echo "✗ DOWN"
fi
echo -n "  Frontend (HTTP):      "
HTTP=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/california-unc/ 2>/dev/null || echo "000")
if [ "$HTTP" = "200" ] || [ "$HTTP" = "302" ]; then echo "✓ HTTP $HTTP"; else echo "✗ HTTP $HTTP"; fi
echo -n "  Database (nwe_unc):   "
if mysql -u root -e "USE nwe_unc; SELECT 1;" >/dev/null 2>&1; then echo "✓ OK"; else echo "✗ FAIL"; fi
echo ""
echo "[OK] Test complete."
