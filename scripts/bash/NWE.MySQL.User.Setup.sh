#!/usr/bin/env bash
# NWE.MySQL.User.Setup.sh — Create all NWE module databases using admin credentials.
# All modules now connect as 'mearvk' (admin user with full privileges).
# Usage: bash scripts/bash/NWE.MySQL.User.Setup.sh

set -euo pipefail

ADMIN_USER="mearvk"
# Source credentials if available (falls back to default)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
_NWE="$(cd "$SCRIPT_DIR/../.." 2>/dev/null && pwd)"
[ -f "$_NWE/.nwe-credentials" ] && source "$_NWE/.nwe-credentials"
ADMIN_PASS="${NWE_DB_PASS:?ERROR: NWE_DB_PASS not set. Create .nwe-credentials or export NWE_DB_PASS.}"

echo "=== NWE MySQL Database Setup ==="

# Source credentials if available (falls back to default)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
_NWE="$(cd "$SCRIPT_DIR/../.." 2>/dev/null && pwd)"
[ -f "$_NWE/.nwe-credentials" ] && source "$_NWE/.nwe-credentials"
mysql -u "$ADMIN_USER" -p"$ADMIN_PASS" <<'SQL'
CREATE DATABASE IF NOT EXISTS nwe_calendar_d44 CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS nwe_calendar_france CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS nwe_japan CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS nwe_russia CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS nwe_mexico CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS nwe_greece_intl CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS nwe_arctic CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS nwe_china CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS nwe_britain CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS nwe_ukraine CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS nwe_strernary CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
SQL

echo "[DONE] All module databases created. Connecting as: mearvk@localhost"
