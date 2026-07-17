#!/bin/bash
set -uo pipefail
TOMCAT_HOME="${1:-${CATALINA_HOME:-/opt/apache-tomcat-11.0.2}}"
rm -rf "$TOMCAT_HOME/webapps/uncw" && echo "  [✓] UNCW undeployed" || echo "  [--] Not deployed"
