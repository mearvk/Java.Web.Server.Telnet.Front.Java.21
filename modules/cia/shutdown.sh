#!/bin/bash
# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
# NitroWebExpressâ„¢ â€” cia Frontend Shutdown
# Undeploys the webapp from Tomcat.
# Usage: bash shutdown.sh [tomcat_home] [--stop-tomcat]
# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MOD_ROOT="$SCRIPT_DIR"
PROJECT_ROOT="$(cd "$MOD_ROOT/../.." && pwd)"
TOMCAT_HOME="${1:-${CATALINA_HOME:-/opt/apache-tomcat-11.0.2}}"
CONTEXT="california-cia"
DEPLOY_DIR="$TOMCAT_HOME/webapps/$CONTEXT"
STOP_TOMCAT=false

for arg in "$@"; do
    if [ "$arg" = "--stop-tomcat" ]; then STOP_TOMCAT=true; fi
done

echo ""
echo "â•”â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•—"
echo "â•‘  cia Frontend â€” Shutdown                                               â•‘"
echo "â•‘  Context: /$CONTEXT                                                      â•‘"
echo "â•‘  Tomcat:  $TOMCAT_HOME                                                    â•‘"
echo "â•šâ•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•"
echo ""

# â”€â”€ 1. Remove webapp from Tomcat â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
if [ -d "$DEPLOY_DIR" ]; then
    echo "  [*] Removing deployment..."
    rm -rf "$DEPLOY_DIR"
    echo "  [âœ“] Webapp undeployed"
else
    echo "  [--] Webapp not deployed"
fi

# Remove WAR file if present
WAR_FILE="$TOMCAT_HOME/webapps/$CONTEXT.war"
if [ -f "$WAR_FILE" ]; then
    rm -f "$WAR_FILE"
    echo "  [âœ“] WAR removed"
fi

# â”€â”€ 2. Optionally stop Tomcat â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
if [ "$STOP_TOMCAT" = true ]; then
    echo "  [*] Stopping Tomcat..."
    if [ -x "$TOMCAT_HOME/bin/shutdown.sh" ]; then
        "$TOMCAT_HOME/bin/shutdown.sh" > /dev/null 2>&1 || true
    else
        sudo systemctl stop tomcat 2>/dev/null || true
    fi
    sleep 2
    echo "  [âœ“] Tomcat stopped"
fi

echo ""
echo "â•”â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•—"
echo "â•‘  cia Frontend Stopped                                                  â•‘"
echo "â•‘                                                                            â•‘"
echo "â•‘  Management:                                                               â•‘"
echo "â•‘  Restart module:   bash start.sh                                           â•‘"
echo "â•‘  Stop backend:     bash shutdown-backend.sh                               â•‘"
echo "â•‘  Shutdown all:     bash ../../scripts/shutdown-all.sh                     â•‘"
echo "â•šâ•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•"
echo ""
