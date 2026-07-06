#!/bin/bash
# cron/integrity-check.sh — Periodic integrity check (cron-safe wrapper)
# Runs post-install-integrity-check.sh and logs output
# Concerns are non-blocking — program continues running

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

bash "${PROJECT_ROOT}/integrity/post-install-integrity-check.sh"
