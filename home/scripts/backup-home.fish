#!/usr/bin/env fish

function backup_home
    # Get current user
    set current_user (whoami)

    # Platform-specific excludes
    set darwin_excludes \
        --exclude="./$current_user/.orbstack" \
        --exclude="./$current_user/.Trash" \
        --exclude="./$current_user/.cache/nix" \
        --exclude="./$current_user/Library/Caches/com.apple.ap.adprivacyd" \
        --exclude="./$current_user/Library/Caches/com.apple.homed" \
        --exclude="./$current_user/Library/Caches/FamilyCircle" \
        --exclude="./$current_user/Library/Caches/com.apple.containermanagerd" \
        --exclude="./$current_user/Library/Caches/com.apple.Safari" \
        --exclude="./$current_user/Library/Caches/CloudKit" \
        --exclude="./$current_user/Library/Caches/com.apple.HomeKit"

    # Go to the parent of home directory - platform agnostic approach
    cd $HOME/..

    set backup_file "/tmp/$current_user.tar"

    # Create the backup using tar
    echo "Creating backup of home directory for $current_user..."
    sudo tar $darwin_excludes -cvf $backup_file $current_user/

    # Check if backup was successful
    if test $status -eq 0
        echo "Backup completed successfully: $backup_file"
    else
        echo "Backup failed!"
        return 1
    end
end

function main
    backup_home
end

main
