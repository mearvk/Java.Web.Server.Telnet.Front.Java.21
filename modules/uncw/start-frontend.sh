#!/bin/bash
set -uo pipefail
MOD_ROOT="$(cd "$(dirname "$0")" && pwd)"; TOMCAT_HOME="${1:-${CATALINA_HOME:-/opt/apache-tomcat-11.0.2}}"; CONTEXT="uncw"
echo "  [*] Deploying UNCW to Tomcat..."; bash "$MOD_ROOT/servlets/deploy-local.sh" "$TOMCAT_HOME"
echo "  [✓] UNCW frontend deployed at /uncw"
