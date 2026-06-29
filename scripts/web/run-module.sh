#!/bin/bash
# NitroWebExpress™ — Run a specific module's cron/scheduled task
# Usage: bash scripts/web/run-module.sh <module-id>
# Example: bash scripts/web/run-module.sh ae6e66
set -e

MODULE_ID="$1"
if [ -z "$MODULE_ID" ]; then echo "Usage: run-module.sh <module-id>"; exit 1; fi

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
CONFIG="$(dirname "$0")/web-deploy-config.xml"

case "$MODULE_ID" in
    ae6e66)
        echo "[*] Running AE6E66 crawl..."
        cd "$PROJECT_ROOT" && java -cp modules/AE6E66/source source.AE6E66Main
        ;;
    futures)
        echo "[*] Running Futures pipeline..."
        cd "$PROJECT_ROOT" && java -cp "modules/black/red/Futures/source:modules/black/red/Futures/jars/*" source.Main
        ;;
    strernary)
        echo "[*] Starting Strernary server..."
        cd "$PROJECT_ROOT" && java -cp "source/strernary:lib/*" source.strernary.StrernaryServer &
        ;;
    *)
        echo "[!] Unknown module: $MODULE_ID"
        echo "    Available: ae6e66, futures, strernary"
        exit 1
        ;;
esac
