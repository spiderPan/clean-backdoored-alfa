#!/bin/bash

# Path to the log file containing the list of site names
LOG_DIR="/var/log/scan"
SITES_LOG_FILE="$LOG_DIR/site_list.log"

# Log file for tracking actions
LOG_FILE="$LOG_DIR/sites_cleanup.log"

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

# Main function to go through the list of sites and clean them
main() {
    if [ ! -f "$SITES_LOG_FILE" ]; then
        echo "Sites log file not found: $SITES_LOG_FILE" | tee -a "$LOG_FILE"
        exit 1
    fi

    while IFS= read -r site; do
        local dir="/home/$site/public_html"
        if [ -d "$dir" ]; then
            echo "Processing site: $site" | tee -a "$LOG_FILE"
            clean_wp_directories "$dir"
            for wp_dir in "wp-admin" "wp-includes"; do
                local target_dir="$dir/$wp_dir"
                
                if [ -d "$target_dir" ]; then
                    local owner=$(stat -c '%U' "$target_dir")
                    
                    if [ "$owner" == "root" ]; then
                        local user=$(basename "$site")
                        reset_permissions "$target_dir" "$user"
                    fi
                fi
            done

            local index_file="$dir/index.php"
            if [ -f "$index_file" ]; then
                local owner=$(stat -c '%U' "$index_file")
                
                if [ "$owner" == "root" ]; then
                    local user=$(basename "$site")
                    reset_file_permissions "$index_file" "$user"
                fi
            fi
        else
            echo "Directory $dir does not exist. Skipping site: $site" | tee -a "$LOG_FILE"
        fi
    done < "$SITES_LOG_FILE"
}

# Run the main function
main
