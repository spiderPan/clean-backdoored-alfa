#!/bin/bash

# Define the parent directory where all your websites are located
PARENT_DIR="/home/*/public_html"

# Define the patterns to search for
PATTERN_FILE_NAME="about.php"
PATTERN_FUNCTION_1="touch("
PATTERN_FUNCTION_2="base64_decode"
PATTERN_CONTENT_1="alfapas.php"
PATTERN_CONTENT_2="PEZpbGVzTWF0Y2ggIi4qXC4oP2k6cGh0bWx8cGhwfFBIUCkkIj4KT3JkZXIgQWxsb3csRGVueQpBbGxvdyBmcm9tIGFsbAo8L0ZpbGVzTWF0Y2g+"
PATTERN_CONTENT_3="loggershell443"
PATTERN_CONTENT_4="Yanz"
PATTERN_CONTENT_5="JhYLEQZqGB4oDH4MEwBdSj0fEBctW1QMPh8UHDoxfxs"
PATTERN_CONTENT_6="goto UMrsh"
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
        if grep -q -e "$PATTERN_FUNCTION_1" -e "$PATTERN_FUNCTION_2" "$file"; then
            echo "Found suspicious file: $file" >> "$LOG_FILE"
            echo "$file" >> "$AFFECTED_FILES_LOG"
        fi
    done
}

# Function to scan for suspicious content in PHP files
scan_file_contents() {
    local dir=$1
    echo "Scanning for suspicious content in PHP files in directory: $dir"
    grep -r --include="*.php" -e "$PATTERN_CONTENT_1" -e "$PATTERN_CONTENT_2" -e "$PATTERN_CONTENT_3" -e "$PATTERN_CONTENT_4" -e "$PATTERN_CONTENT_5" -e "$PATTERN_CONTENT_6" "$dir" | tee -a "$LOG_FILE" | awk -F: '{print $1}' >> "$AFFECTED_FILES_LOG"
}

# Function to scan for a specific snippet in any file
scan_specific_snippet() {
    local dir=$1
    echo "Scanning for specific snippet in directory: $dir"
    grep -r -e "$PATTERN_CONTENT_1" -e "$PATTERN_CONTENT_2" -e "$PATTERN_CONTENT_3" -e "$PATTERN_CONTENT_5" -e "$PATTERN_CONTENT_6" "$dir" | tee -a "$LOG_FILE" | awk -F: '{print $1}' >> "$AFFECTED_FILES_LOG"
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

# Function to clean infected PHP files
delete_affected_files() {
    while IFS= read -r path; do
        if [ -f "$path" ]; then
            echo "Deleting file: $path"
            rm "$path"
        elif [ -d "$path" ]; then
            echo "Deleting directory: $path"
            rm -r "$path"
        else
            echo "File or directory not found or already deleted: $path"
        fi
    done < "$AFFECTED_FILES_LOG"
    echo "Deletion completed."
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
    else
        echo "Scanning all websites under the parent directory: $PARENT_DIR"
        # Find all directories under the parent directory and scan them
        for website_dir in $PARENT_DIR; do
            scan_file_names "$website_dir"
            scan_file_contents "$website_dir"
            scan_specific_snippet "$website_dir"
            scan_fake_plugin "$website_dir"
        done
    fi

    echo "Scan completed. Results are logged in $LOG_FILE and affected files are logged in $AFFECTED_FILES_LOG"

    if [ "$mode" = "clean" ]; then
        delete_affected_files
    fi
}

# Check for the correct usage
if [ "$#" -lt 1 ]; then
    echo "Usage: $0 {scan|clean} [/path/to/specific/site]"
    exit 1
fi

# Run the main function with the provided arguments
main "$@"
