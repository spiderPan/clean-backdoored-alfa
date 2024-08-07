#!/bin/bash

# Define the log file containing the affected files
LOG_DIR="/var/log/scan"
AFFECTED_FILES_LOG="$LOG_DIR/clean_files.log"

# Check if the log file exists and is readable
if [ ! -f "$AFFECTED_FILES_LOG" ]; then
  echo "Log file not found: $AFFECTED_FILES_LOG"
  exit 1
fi

# Read and delete each file listed in the log file
while IFS= read -r file; do
  if [ -f "$file" ]; then
    echo "Deleting file: $file"
    rm "$file"
  else
    echo "File not found or already deleted: $file"
  fi
done < "$AFFECTED_FILES_LOG"

echo "Deletion of affected files completed."
