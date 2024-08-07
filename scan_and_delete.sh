#!/bin/bash

# Define the parent directory where all your websites are located
PARENT_DIR="/home/*/public_html"

# Define the patterns to search for
PATTERN_FILE_NAME="about.php"
PATTERN_FUNCTION_1="touch("
PATTERN_FUNCTION_2="base64_decode"
PATTERN_FUNCTION_3="goto UMrsh"
PATTERN_CONTENT_1="alfapas.php"
PATTERN_CONTENT_2="PEZpbGVzTWF0Y2ggIi4qXC4oP2k6cGh0bWx8cGhwfFBIUCkkIj4KT3JkZXIgQWxsb3csRGVueQpBbGxvdyBmcm9tIGFsbAo8L0ZpbGVzTWF0Y2g+"
PATTERN_CONTENT_3="loggershell443"
PATTERN_CONTENT_4="Yanz"
PATTERN_CONTENT_5="JhYLEQZqGB4oDH4MEwBdSj0fEBctW1QMPh8UHDoxfxs"
PATTERN_PLUGIN="erin"

# Define the log files
LOG_FILE="/var/log/suspicious_files_scan.log"
AFFECTED_FILES_LOG="/var/log/affected_files.log"

# Ensure the log files exist and are empty
: > "$LOG_FILE"
: > "$AFFECTED_FILES_LOG"

# Function to scan for suspicious files by name
scan_file_names() {
    local dir=$1
    echo "Scanning for files named $PATTERN_FILE_NAME in directory: $dir"
    find "$dir" -type f -name "$PATTERN_FILE_NAME" | while read -r file; do
        if grep -q -e "$PATTERN_FUNCTION_1" -e "$PATTERN_FUNCTION_2" -e "$PATTERN_FUNCTION_3" "$file"; then
            echo "Found suspicious file: $file" >> "$LOG_FILE"
            echo "$file" >> "$AFFECTED_FILES_LOG"
        fi
    done
}

# Function to scan for suspicious content in PHP files
scan_file_contents() {
    local dir=$1
    echo "Scanning for suspicious content in PHP files in directory: $dir"
    grep -r --include="*.php" -e "$PATTERN_CONTENT_1" -e "$PATTERN_CONTENT_2" -e "$PATTERN_CONTENT_3" "$dir" | tee -a "$LOG_FILE" | awk -F: '{print $1}' >> "$AFFECTED_FILES_LOG"
}

# Function to scan for a specific snippet in any file
scan_specific_snippet() {
    local dir=$1
    echo "Scanning for specific snippet in directory: $dir"
    grep -r -e "$PATTERN_CONTENT_5" "$dir" | tee -a "$LOG_FILE" | awk -F: '{print $1}' >> "$AFFECTED_FILES_LOG"
}

# Function to scan for the fake plugin "erin" and log its directory
scan_fake_plugin() {
    local dir=$1
    echo "Scanning for fake plugin '$PATTERN_PLUGIN' in directory: $dir"
    find "$dir" -type d -name "$PATTERN_PLUGIN" | while read -r plugin_dir; do
        echo "Found fake plugin directory: $plugin_dir" >> "$LOG_FILE"
        echo "$plugin_dir" >> "$AFFECTED_FILES_LOG"
    done
}

# Function to scan for unexpected files in wp-admin
scan_unexpected_files() {
    local dir=$1
    echo "Scanning for unexpected files in wp-admin in directory: $dir"
    find "$dir/wp-admin" -type f -name "wp-blog-header.php" | while read -r file; do
        echo "Found unexpected file in wp-admin: $file" >> "$LOG_FILE"
        echo "$file" >> "$AFFECTED_FILES_LOG"
    done
}

# Function to clean infected PHP files
clean_infected_files() {
    while IFS= read -r file; do
        if [ -f "$file" ]; then
            echo "Cleaning file: $file"
            sed -i '/goto UMrsh/d' "$file"
            sed -i '/function get_u/d' "$file"
            sed -i '/function post_u/d' "$file"
        elif [ -d "$file" ]; then
            echo "Cleaning directory: $file"
            rm -r "$file"
        else
            echo "File or directory not found or already cleaned: $file"
        fi
    done < "$AFFECTED_FILES_LOG"
    echo "Cleaning completed."
}

# Main function to run the scan and optionally clean infected files
main() {
    local mode=$1

    # Check if a specific path is given as a parameter
    if [ -n "$2" ]; then
        TARGET_DIR="$2"
        echo "Scanning specific directory: $TARGET_DIR"
        scan_file_names "$TARGET_DIR"
        scan_file_contents "$TARGET_DIR"
        scan_specific_snippet "$TARGET_DIR"
        scan_fake_plugin "$TARGET_DIR"
        scan_unexpected_files "$TARGET_DIR"
    else
        echo "Scanning all websites under the parent directory: $PARENT_DIR"
        # Find all directories under the parent directory and scan them
        for website_dir in $PARENT_DIR; do
            scan_file_names "$website_dir"
            scan_file_contents "$website_dir"
            scan_specific_snippet "$website_dir"
            scan_fake_plugin "$website_dir"
            scan_unexpected_files "$website_dir"
        done
    fi

    echo "Scan completed. Results are logged in $LOG_FILE and affected files are logged in $AFFECTED_FILES_LOG"

    if [ "$mode" = "clean" ]; then
        clean_infected_files
    fi
}

# Check for the correct usage
if [ "$#" -lt 1 ]; then
    echo "Usage: $0 {scan|clean} [/path/to/specific/site]"
    exit 1
fi

# Run the main function with the provided arguments
main "$@"
