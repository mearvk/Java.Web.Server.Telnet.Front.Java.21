#!/bin/bash
# ============================================================
# FETCH 44H — Pledge of Living Consciousness / One Contract
# D44/N44 — UNC Chapel Hill
# Authenticity guaranteed by Max Rupplin, Senior Honest
# MEARVK LLC — United States
# ============================================================
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CP="$PROJECT_DIR/output/production/Futures:$(echo "$PROJECT_DIR"/jars/*.jar | tr ' ' ':')"

echo "============================================================"
echo " 44H — Proof of Living Consciousness / One Contract"
echo " D44/N44 — University of North Carolina at Chapel Hill"
echo " Senior.Senate.Attorney.E44Hrs"
echo "============================================================"
echo ""

# Ensure database exists
if command -v mysql &>/dev/null; then
    mysql -e "CREATE DATABASE IF NOT EXISTS pledge_44h CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci" 2>/dev/null ||
    sudo mysql -e "CREATE DATABASE IF NOT EXISTS pledge_44h CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci" 2>/dev/null
    mysql pledge_44h < "$PROJECT_DIR/sql/schema-44h.sql" 2>/dev/null ||
    sudo mysql < "$PROJECT_DIR/sql/schema-44h.sql" 2>/dev/null
fi

java -cp "$CP" ai.server.Pledge44HFetcher

echo ""
echo " Authenticity: Max Rupplin, Senior Honest — MEARVK LLC"
echo "============================================================"
