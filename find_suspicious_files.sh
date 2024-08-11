#!/bin/bash

# Define the parent directory where all accounts are located
PARENT_DIR="/home"

# Define the log files
LOG_DIR="/var/log/scan"
LOG_FILE="$LOG_DIR/scan_suspicious.log"
AFFECTED_FILES_LOG="$LOG_DIR/clean_files.log"
mkdir -p "$LOG_DIR"

# Ensure the log files exist and are empty
: > "$LOG_FILE"
: > "$AFFECTED_FILES_LOG"

# Define patterns to search for in content
PATTERN_FUNCTIONS=("goto UMrsh")
PATTERN_CONTENTS=(
  "alfapas.php"
  "md5(md5(md5"
  "PEZpbGVzTWF0Y2ggIi4qXC4oP2k6cGh0bWx8cGhwfFBIUCkkIj4KT3JkZXIgQWxsb3csRGVueQpBbGxvdyBmcm9tIGFsbAo8L0ZpbGVzTWF0Y2g+"
  "loggershell443"
  "XSnyLio6byn2NhIhXlIhMiX1HisyNif5Hj7wayAgU/@3HisyNiT5HlH1MlIhHisyNiHwLinhS"
  "XSn/Myo6byn0NhIhMiYhMhH6byn3NhIXU/ksX1X7OBH6byn2NhIhMlIhXiX1HisyNiDxNhIKT1Y2SjIA"
  "teg_ini1ledoced_46"
  "JhYLEQZqGB4oDH4MEwBdSj0fEBctW1QMPh8UHDoxfxs"
  "goto UMrsh"
  "tXpjcGbhlm5sJx3bdtKxbfOLvtjq2Lb5xUkn6djq2LbTsW2r"
  "112\150\x59\114\x45\121\132\161\x47\x42\x34\157\x44\110\64\x4d"
  "pk-fr/yakpro-po"
  "disanfang.py"
)
PATTERN_PLUGIN="erin"



# Function to scan for suspicious content in PHP files
scan_file_contents() {
    local dir=$1
    echo "Scanning for suspicious content in PHP files in directory: $dir"
    for content in "${PATTERN_CONTENTS[@]}"; do
        grep -r --include="*.php" -e "$content" "$dir" 2>/dev/null | tee -a "$LOG_FILE" | awk -F: '{print $1}' >> "$AFFECTED_FILES_LOG"
    done
    for func in "${PATTERN_FUNCTIONS[@]}"; do
        grep -r --include="*.php" -e "$func" "$dir" 2>/dev/null | tee -a "$LOG_FILE" | awk -F: '{print $1}' >> "$AFFECTED_FILES_LOG"
    done

    find "$dir" -type f -path "*/wp-content/wp-configs.php" | while read -r file; do
        echo "Found wp-configs.php: $file" | tee -a "$LOG_FILE"
    done
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

    for account_dir in $PARENT_DIR/*; do
        local public_html="$account_dir/public_html"
        
        if [ -d "$public_html" ]; then
            echo "Processing account: $account_dir"

            # Step 1: Scan for suspicious content in PHP files
            scan_file_contents "$public_html"

            # Step 2: Scan for fake plugin
            scan_fake_plugin "$public_html"
        fi
    done

    echo "Scan completed. Results are logged in $LOG_FILE and affected files are logged in $AFFECTED_FILES_LOG"

    if [ "$mode" = "clean" ]; then
        delete_affected_files
    fi
}

# Check for the correct usage
if [ "$#" -lt 1 ]; then
    echo "Usage: $0 {scan|clean}"
    exit 1
fi

# Run the main function with the provided arguments
main "$@"
