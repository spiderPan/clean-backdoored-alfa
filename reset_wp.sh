#!/bin/bash

# Path to the log file for tracking actions
LOG_DIR="/var/log/scan"
LOG_FILE="$LOG_DIR/sites_cleanup.log"
SITE_LIST_LOG="$LOG_DIR/site_list.log"

# Ensure the log file exists and is empty
: > "$LOG_FILE"

# Function to clean wp-admin and wp-includes directories
clean_wp_directories() {
    local dir=$1
    echo "Cleaning wp-admin and wp-includes directories in: $dir" | tee -a "$LOG_FILE"
    rm -rf "$dir/wp-admin"
    rm -rf "$dir/wp-includes"
    wp core download --force --skip-content --allow-root --path="$dir" | tee -a "$LOG_FILE"
    echo "Reinstallation of wp-admin and wp-includes completed for: $dir" | tee -a "$LOG_FILE"
}

flush_rewrite_rules() {
    local dir=$1
    echo "Flushing rewrite rules in $dir" | tee -a "$LOG_FILE"
    wp rewrite flush --hard --allow-root --path="$dir"
}

reset_permissions() {
    local dir=$1
    local user=$2
    echo "Resetting permissions for $dir to user $user" | tee -a "$LOG_FILE"
    chown -R "$user:$user" "$dir"
    chmod -R 755 "$dir"
}

# Function to reset ownership and permissions for a single file
reset_file_permissions() {
    local file=$1
    local user=$2
    echo "Resetting permissions for $file to user $user" | tee -a "$LOG_FILE"
    chown "$user:$user" "$file"
    chmod 644 "$file"
}

# Main function to go through the CSV and process each site listed in site_list.log
main() {
    if [ "$#" -ne 1 ]; then
        echo "Usage: $0 /path/to/accounts.csv" | tee -a "$LOG_FILE"
        exit 1
    fi

    CSV_FILE="$1"

    if [ ! -f "$CSV_FILE" ]; then
        echo "CSV file not found: $CSV_FILE" | tee -a "$LOG_FILE"
        exit 1
    fi

    if [ ! -f "$SITE_LIST_LOG" ]; then
        echo "Sites list log file not found: $SITE_LIST_LOG" | tee -a "$LOG_FILE"
        exit 1
    fi

    # Read the sites from site_list.log into an array
    mapfile -t sites_to_process < "$SITE_LIST_LOG"

    IFS=","
    while read -r account wp_dir; do
        # Skip header or empty lines
        if [ "$account" == "account" ] || [ -z "$account" ] || [ -z "$wp_dir" ]; then
            continue
        fi

        # Check if this account is in the sites to process
        if [[ " ${sites_to_process[@]} " =~ " ${account} " ]]; then
            echo "Processing account: $account with WP directory: $wp_dir" | tee -a "$LOG_FILE"

            if [ -d "$wp_dir" ]; then
                flush_rewrite_rules "$wp_dir"
                clean_wp_directories "$wp_dir"

                for wp_subdir in "wp-admin" "wp-includes"; do
                    local target_dir="$wp_dir/$wp_subdir"
                    
                    if [ -d "$target_dir" ]; then
                        local owner=$(stat -c '%U' "$target_dir")
                        
                        if [ "$owner" == "root" ]; then
                            reset_permissions "$target_dir" "$account"
                        fi
                    fi
                done

                local index_file="$wp_dir/index.php"
                if [ -f "$index_file" ]; then
                    local owner=$(stat -c '%U' "$index_file")
                    
                    if [ "$owner" == "root" ]; then
                        reset_file_permissions "$index_file" "$account"
                    fi
                fi
            else
                echo "Directory $wp_dir does not exist. Skipping account: $account" | tee -a "$LOG_FILE"
            fi
        fi
    done < "$CSV_FILE"
}

# Run the main function
main "$@"
