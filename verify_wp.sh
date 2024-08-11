#!/bin/bash

# Define the log files
LOG_DIR="/var/log/scan"
LOG_FILE="$LOG_DIR/wp_verify_checksums.log"
SITE_LIST_LOG="$LOG_DIR/site_list.log"
AFFECTED_FILES_LOG="$LOG_DIR/clean_files.log"

# Create or clear the log files
mkdir -p "$LOG_DIR"
> "$LOG_FILE"
> "$SITE_LIST_LOG"
> "$AFFECTED_FILES_LOG"

# List of expected files in the WordPress root directory
EXPECTED_FILES=(
    "index.php"
    "wp-activate.php"
    "wp-blog-header.php"
    "wp-comments-post.php"
    "wp-config-sample.php"
    "wp-config.php"
    "wp-cron.php"
    "wp-links-opml.php"
    "wp-load.php"
    "wp-login.php"
    "wp-mail.php"
    "wp-settings.php"
    "wp-signup.php"
    "wp-trackback.php"
    "xmlrpc.php"
    "wordfence-waf.php" # Added by Wordfence
)

# Function to check for extra files
check_extra_files() {
    local dir=$1
    echo "Checking for extra files in $dir" | tee -a "$LOG_FILE"

    # Get the list of files in the root directory
    for file in "$dir"/*.php; do
        filename=$(basename "$file")
        if [[ ! " ${EXPECTED_FILES[@]} " =~ " ${filename} " ]]; then
            echo "Extra PHP file found: $file" | tee -a "$LOG_FILE"
            echo "$file" >> "$AFFECTED_FILES_LOG"
        fi
    done
}

# Function to process each WP install directory
process_wp_directory() {
    local account=$1
    local wp_dir=$2

    echo "Processing $account: $wp_dir" | tee -a "$LOG_FILE"

    # Run the WP CLI command and capture the output
    output=$(wp core verify-checksums --allow-root --path="$wp_dir" 2>&1)
    
    # Check if it's not a WordPress installation
    if echo "$output" | grep -iq "Error: This does not seem to be a WordPress install."; then
        echo "$wp_dir does not seem to be a WordPress install." | tee -a "$LOG_FILE"
        return
    fi

    # Check if there were any warnings or other errors
    if echo "$output" | grep -iE "warning|error"; then
        echo "Issues found in $wp_dir:" >> "$LOG_FILE"
        echo "$output" >> "$LOG_FILE"
        echo "------------------------" >> "$LOG_FILE"
      
        # Extract the site name from the path and add it to the site list log
        echo "$account" >> "$SITE_LIST_LOG"
      
        # Add the full path of any affected files to the affected files log, ignoring specific files
        echo "$output" | grep -oP 'Warning: File should not exist: \K[^ ]+' | while read -r file; do
            base_file=$(basename "$file")
            if [[ "$base_file" != "readme.html" && "$base_file" != "license.txt" ]]; then
                echo "$wp_dir/$file" >> "$AFFECTED_FILES_LOG"
            fi
        done
    fi

    check_extra_files "$wp_dir"
}

# Main script execution
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 /path/to/accounts.csv"
    exit 1
fi

CSV_FILE="$1"

# Read the CSV file and process each line
IFS=","
while read -r account wp_dir; do
    # Ignore the header line if present
    if [ "$account" != "account" ]; then
        process_wp_directory "$account" "$wp_dir"
    fi
done < "$CSV_FILE"

echo "Verification complete. Check $LOG_FILE for details, $SITE_LIST_LOG for sites with issues, and $AFFECTED_FILES_LOG for affected files."
