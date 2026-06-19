#!/usr/bin/env bash
# aes2-config-backup.sh — Backs up aes2-config.xml and related source files
# to backups/{date}/ before any config change is applied.
# MEARVK LLC — Max Rupplin
#
# Usage: bash source/encryption/module/backups/aes2-config-backup.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../../.." && pwd)"
MODULE="$ROOT/source/encryption/module"
DATE=$(date +%Y-%m-%d)
BACKUP_DIR="$MODULE/backups/$DATE"

mkdir -p "$BACKUP_DIR"

# Backup config
cp "$MODULE/aes2-config.xml" "$BACKUP_DIR/aes2-config.xml"

# Backup AES2 source files
cp "$MODULE/aes/two/EncryptionModule.java" "$BACKUP_DIR/EncryptionModule.java"
cp "$MODULE/aes/two/EncryptionModuleRunner.java" "$BACKUP_DIR/EncryptionModuleRunner.java"

# Backup flags
cp "$MODULE/flags/KnownUSServerFlag.java" "$BACKUP_DIR/KnownUSServerFlag.java" 2>/dev/null || true
cp "$MODULE/flags/UnknownUSAServerFlag.java" "$BACKUP_DIR/UnknownUSAServerFlag.java" 2>/dev/null || true

# Backup math
cp "$MODULE/math/ConvergentFields.java" "$BACKUP_DIR/ConvergentFields.java" 2>/dev/null || true
cp "$MODULE/math/ConvergentFieldsInfoManager.java" "$BACKUP_DIR/ConvergentFieldsInfoManager.java" 2>/dev/null || true
cp "$MODULE/math/HypotheticalLengthOfPrecept.java" "$BACKUP_DIR/HypotheticalLengthOfPrecept.java" 2>/dev/null || true
cp "$MODULE/math/PreceptPruner.java" "$BACKUP_DIR/PreceptPruner.java" 2>/dev/null || true

echo "[BACKUP] Saved to: $BACKUP_DIR"
ls -la "$BACKUP_DIR"
