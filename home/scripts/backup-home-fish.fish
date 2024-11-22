#!/usr/bin/env fish

# Global variables
set --global current_user (whoami)
set --global backup_file "/tmp/$current_user.tar.gz"

# Platform-specific excludes
set --global darwin_excludes \
    --exclude="./$current_user/.orbstack" \
    --exclude="./$current_user/.Trash" \
    --exclude="./$current_user/.cache/nix" \
    --exclude="./$current_user/.terraform.d" \
    --exclude="./$current_user/Library/Application Support/rancher-desktop" \
    --exclude="./$current_user/Library/Application Support/Google" \
    --exclude="./$current_user/Library/Application Support/Slack" \
    --exclude="./$current_user/Library/Caches" \
    --exclude="./$current_user/Library/Caches/com.apple.ap.adprivacyd" \
    --exclude="./$current_user/Library/Caches/com.apple.homed" \
    --exclude="./$current_user/Library/Caches/FamilyCircle" \
    --exclude="./$current_user/Library/Caches/com.apple.containermanagerd" \
    --exclude="./$current_user/Library/Caches/com.apple.Safari" \
    --exclude="./$current_user/Library/Caches/CloudKit" \
    --exclude="./$current_user/Library/Caches/com.apple.HomeKit" \
    --exclude="./$current_user/Library/Group Containers" \
    --exclude="./$current_user/OrbStack" \
    --exclude="./**/*.sock" \
    --exclude="./.gnupg/S.*"

function backup_home
    pushd $HOME/..
    echo "Creating backup of home directory for $current_user..."
    tar $darwin_excludes -cvf - $current_user/ | pigz > $backup_file
end

function upload_backup
    echo "Uploading backup to drive:..."
    rclone --progress copy $backup_file "drive:"
end

function cleanup_backup
    echo "Cleaning up temporary backup file: $backup_file..."
    rm $backup_file
end

function main
    backup_home
    and upload_backup
    and cleanup_backup
end

main
