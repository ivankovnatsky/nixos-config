#!/usr/bin/env fish

# Global variables
set --global current_user (whoami)
set --global backup_file "/tmp/$current_user.tar.gz"

# Platform-specific excludes
set --global darwin_excludes \
    --exclude="./$current_user/.orbstack" \
    --exclude="./$current_user/.Trash" \
    --exclude="./$current_user/.cache/nix" \
    --exclude="./$current_user/Library/Caches/com.apple.ap.adprivacyd" \
    --exclude="./$current_user/Library/Caches/com.apple.homed" \
    --exclude="./$current_user/Library/Caches/FamilyCircle" \
    --exclude="./$current_user/Library/Caches/com.apple.containermanagerd" \
    --exclude="./$current_user/Library/Caches/com.apple.Safari" \
    --exclude="./$current_user/Library/Caches/CloudKit" \
    --exclude="./$current_user/Library/Caches/com.apple.HomeKit" \
    --exclude="./$current_user/Library/Group Containers" \
    --exclude="./**/*.sock" \
    --exclude="./.gnupg/S.*"

function backup_home
    pushd $HOME/..

    echo "Creating backup of home directory for $current_user..."
    sudo -v
    
    sudo tar $darwin_excludes -cf - $current_user/ | \
        pv -s (du -sk $current_user | awk '{print $1 * 1024}') | pigz > $backup_file

    popd

    if test $status -eq 0
        set backup_size (du -h $backup_file | awk '{print $1}')
        echo "Backup completed successfully: $backup_file (Size: $backup_size)"
        return 0
    else
        echo "Backup failed!"
        return 1
    end
end

function upload_backup
    if test -f $backup_file
        echo "Uploading backup to drive:..."
        rclone --progress copy $backup_file "drive:"
        return $status
    else
        echo "Backup file not found: $backup_file"
        return 1
    end
end

function cleanup_backup
    if test -f $backup_file
        echo "Cleaning up temporary backup file: $backup_file..."
        rm $backup_file
        if test $status -eq 0
            echo "Cleanup completed successfully"
            return 0
        else
            echo "Failed to remove temporary backup file!"
            return 1
        end
    end
end

function main
    if backup_home
        if upload_backup
            cleanup_backup
        end
    end
end

main
