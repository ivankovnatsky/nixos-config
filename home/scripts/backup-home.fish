#!/usr/bin/env fish

# Global variables
set --global current_user (whoami)
set --global backup_file "/tmp/$current_user.tar.gz"
set --global min_backup_size_gb 5
set --global max_backup_size_gb 20
set --global min_backup_size_bytes (math "$min_backup_size_gb * 1024 * 1024 * 1024")
set --global max_backup_size_bytes (math "$max_backup_size_gb * 1024 * 1024 * 1024")

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
    sudo -v
    
    # Simple pipeline with basic pv
    sudo tar $darwin_excludes -cf - $current_user/ | pv | pigz > $backup_file
    
    if test -f $backup_file
        set file_size (stat -f %z $backup_file)
        if test $file_size -gt $min_backup_size_bytes
            if test $file_size -lt $max_backup_size_bytes
                set backup_size (du -h $backup_file | awk '{print $1}')
                echo "Backup completed successfully: $backup_file (Size: $backup_size)"
                return 0
            end
            echo "Backup file too large (> $max_backup_size_gb GB)"
            return 1
        end
        echo "Backup file too small (< $min_backup_size_gb GB)"
        return 1
    end
    echo "Backup file was not created"
    return 1
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
    upload_backup
    cleanup_backup
end

main
