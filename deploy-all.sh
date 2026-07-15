#!/bin/bash
# NitroWebExpress™ — Deploy All (convenience wrapper)
# Runs from project root. Delegates to scripts/web/deploy-all.sh
exec bash "$(dirname "$0")/scripts/web/deploy-all.sh" "$@"
