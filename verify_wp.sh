#!/bin/bash

# Define the log files
LOG_DIR="/var/log/scan"
LOG_FILE="$LOG_DIR/wp_verify_checksums.log"
SITE_LIST_LOG="$LOG_DIR/site_list.log"
AFFECTED_FILES_LOG="$LOG_DIR/clean_files.log"

# Create or clear the log files
> "$LOG_FILE"
> "$SITE_LIST_LOG"
> "$AFFECTED_FILES_LOG"

# Iterate through all user directories
for user_dir in /home/*/public_html; do
  # Check if it's a directory
  if [ -d "$user_dir" ]; then
    # Run the WP CLI command and capture the output
    output=$(wp core verify-checksums --allow-root --path="$user_dir" 2>&1)
    
    # Check if it's not a WordPress installation
    if echo "$output" | grep -iq "Error: This does not seem to be a WordPress install."; then
      continue
    fi

    # Check if there were any warnings or other errors
    if echo "$output" | grep -iE "warning|error"; then
      echo "Issues found in $user_dir:" >> "$LOG_FILE"
      echo "$output" >> "$LOG_FILE"
      echo "------------------------" >> "$LOG_FILE"
      
      # Extract the site name from the path and add it to the site list log
      site_name=$(basename "$(dirname "$user_dir")")
      echo "$site_name" >> "$SITE_LIST_LOG"
      
      # Add the full path of any affected files to the affected files log, ignoring specific files
      echo "$output" | grep -oP 'Warning: File should not exist: \K[^ ]+' | while read -r file; do
        base_file=$(basename "$file")
        if [[ "$base_file" != "readme.html" && "$base_file" != "license.txt" ]]; then
          echo "$user_dir/$file" >> "$AFFECTED_FILES_LOG"
        fi
      done
    fi
  fi
done

echo "Verification complete. Check $LOG_FILE for details, $SITE_LIST_LOG for sites with issues, and $AFFECTED_FILES_LOG for affected files."
