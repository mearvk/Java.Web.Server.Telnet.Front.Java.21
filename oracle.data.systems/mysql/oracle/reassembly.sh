#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Configuration
# The prefix used when splitting the files (e.g., "mysql_dump_part_")
PREFIX="mysql_9.7.0_part_"
# The name of the final reassembled SQL file
OUTPUT_FILE="mysql_9.7.0_linux"

# 1. Check if the directory has any files matching the prefix
if ! ls ${PREFIX}* 1> /dev/null 2>&1; then
    echo "Error: No files found matching the prefix '${PREFIX}'."
    echo "Please check your PREFIX and directory."
    exit 1
fi

echo "Reassembling files into ${OUTPUT_FILE}..."

# 2. Concatenate files using natural sorting
# This sorts alphabetically and numerically (e.g., part_2 comes before part_10)
cat $(ls -v ${PREFIX}*) > "$OUTPUT_FILE"

echo "Reassembly complete! The file is saved as ${OUTPUT_FILE}."
echo "File validation (Line count / Size):"
ls -lh "$OUTPUT_FILE"
wc -l "$OUTPUT_FILE"
