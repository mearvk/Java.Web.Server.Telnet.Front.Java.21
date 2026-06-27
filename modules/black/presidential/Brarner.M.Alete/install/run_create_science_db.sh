#!/bin/bash
echo "--- Creating Science Database ---"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/../configuration"

mysql --defaults-extra-file="$CONFIG_DIR/.my.cnf" < "$SCRIPT_DIR/create_science_db.sql"

if [ $? -eq 0 ]; then
    echo "Science database created successfully."
    echo "Tables:"
    mysql --defaults-extra-file="$CONFIG_DIR/.my.cnf" -e "USE Science; SHOW TABLES;"
else
    echo "Failed. Check MySQL credentials in $CONFIG_DIR/.my.cnf"
fi
