#!/bin/bash
# cron/mysql-backup.sh — Daily MySQL backup for all NWE databases

BACKUP_DIR="/var/log/nwe/backups/$(date +%Y-%m-%d)"
mkdir -p "$BACKUP_DIR"

DATABASES="nwe_japan nwe_russia nwe_mexico nwe_greece_intl nwe_gray_registry nwe_gray85_registry green_durham_grass_and_herb democratic_d500"

for db in $DATABASES; do
    if mysqldump --defaults-file=/etc/mysql/debian.cnf "$db" > "${BACKUP_DIR}/${db}.sql" 2>/dev/null; then
        echo "$(date -Iseconds) OK backup ${db}"
    else
        echo "$(date -Iseconds) SKIP ${db} (not present or access denied)"
    fi
done

# Prune backups older than 14 days
find /var/log/nwe/backups -type d -mtime +14 -exec rm -rf {} + 2>/dev/null
