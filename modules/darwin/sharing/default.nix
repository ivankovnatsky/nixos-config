{ config
, lib
, pkgs
, ...
}:

with lib;

let
  cfg = config.local.services.macosFileSharing;

  shareOpts =
    { name, config, ... }:
    {
      options = {
        path = mkOption {
          type = types.str;
          description = "Path to the directory to share";
          example = "/Volumes/ExternalDrive";
        };

        name = mkOption {
          type = types.str;
          description = "Name of the share";
          default = name;
        };
      };
    };
in
{
  options.local.services.macosFileSharing = {
    enable = mkEnableOption "macOS file sharing service";

    shares = mkOption {
      type = types.attrsOf (types.submodule shareOpts);
      default = { };
      description = "Set of shares to configure";
      example = literalExpression ''
        {
          "Media" = {
            path = "/Volumes/ExternalDrive/Media";
          };
        }
      '';
    };
  };

  config = {
    # Use extraActivation for configuring file sharing
    system.activationScripts.extraActivation.text = mkIf cfg.enable ''
      # Basic macOS File Sharing setup
      echo "Setting up macOS file sharing..."

      # Check if file sharing is already enabled
      echo "Checking file sharing service status..."
      SMB_ENABLED=$(sudo defaults read /Library/Preferences/SystemConfiguration/com.apple.services 2>/dev/null | grep -c 'com.apple.smb.server" = 1' || echo "0")
      SMB_RUNNING=$(sudo launchctl list | grep -c com.apple.smbd || echo "0")

      if [ "$SMB_ENABLED" -eq 1 ] && [ "$SMB_RUNNING" -gt 0 ]; then
        echo "File sharing service is already enabled."
      else
        # Enable File Sharing in System Settings
        echo "Enabling File Sharing service..."
        sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.smbd.plist
        sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.services \
          "com.apple.smb.server" -bool true
        echo "File sharing service has been enabled."
      fi

      # Use a system-wide location for tracking shared folders
      TRACKING_DIR="/var/lib/nix-darwin-shared"
      echo "Creating tracking directory at $TRACKING_DIR"
      sudo mkdir -p "$TRACKING_DIR"
      sudo chmod 755 "$TRACKING_DIR"

      # Get all shares that currently exist
      SHARE_INFO=$(sharing -l)

      echo "Checking configured share paths..."
      ${concatStringsSep "\n" (
        mapAttrsToList (name: share: ''
          # Create a unique tracking file for this share
          SHARE_TRACK_FILE="$TRACKING_DIR/${share.name}.share"
          echo "${share.path}" | sudo tee "$SHARE_TRACK_FILE" > /dev/null
          sudo chmod 644 "$SHARE_TRACK_FILE"

          # Check if the path exists
          if [ ! -d "${share.path}" ]; then
            echo "Warning: Path ${share.path} does not exist. Would add this volume if it existed."
          else
            echo "Path ${share.path} exists." 
            
            # Capture all existing share information
            SHARE_INFO=$(sharing -l)
            
            # Check if the name is already used for a different path
            if echo "$SHARE_INFO" | grep -A 3 "name:.*${share.name}" | grep "path:" | grep -v "${share.path}" > /dev/null; then
              echo "Name '${share.name}' is already used for a different path. Removing old share first..."
              sharing -r "${share.name}" || echo "Failed to remove old share."
              echo "Adding share '${share.name}' for path ${share.path}..."
              sharing -a "${share.path}" -S "${share.name}" || echo "Failed to add share. The name or path might already be shared with different settings."
            # Check if the path is already shared with this name
            elif echo "$SHARE_INFO" | grep -A 3 "name:.*${share.name}" | grep "path:" | grep -q "${share.path}"; then
              echo "Path ${share.path} is already shared as '${share.name}'. Not modifying."
            # Check if the path is already shared with a different name
            elif echo "$SHARE_INFO" | grep "path:" | grep -q "${share.path}"; then
              echo "Path ${share.path} is already shared with a different name. Not modifying."
            else
              echo "Adding share '${share.name}' for path ${share.path}..."
              # Actually add the share
              sharing -a "${share.path}" -S "${share.name}" || echo "Failed to add share. The name or path might already be shared with different settings."
            fi
          fi
        '') cfg.shares
      )}

      # Find and remove shares that are no longer in config
      echo "Checking for shares to remove..."
      if [ -d "$TRACKING_DIR" ] && ls "$TRACKING_DIR"/*.share 1> /dev/null 2>&1; then
        for tracking_file in "$TRACKING_DIR"/*.share; do
          if [ -f "$tracking_file" ]; then
            share_name=$(basename "$tracking_file" .share)
            share_path=$(cat "$tracking_file")
            
            # Check if this share still exists in our config
            FOUND=0
            ${concatStringsSep "\n" (
              mapAttrsToList (name: share: ''
                if [ "${share.name}" = "$share_name" ] && [ "${share.path}" = "$share_path" ]; then
                  FOUND=1
                fi
              '') cfg.shares
            )}
            
            # If not found in config and exists in system, remove it
            if [ "$FOUND" = "0" ]; then
              echo "Removing previously managed share: $share_name (path: $share_path)"
              if echo "$SHARE_INFO" | grep "name:" | grep -q "$share_name"; then
                sharing -r "$share_name" || echo "Failed to remove share: $share_name"
              else
                echo "Share $share_name no longer exists in system, removing tracking file"
              fi
              # Remove tracking file
              sudo rm "$tracking_file"
            fi
          fi
        done
      fi

      echo "File sharing setup complete."
    '';

    # Use postActivation for deactivation
    system.activationScripts.postActivation.text = mkIf (!cfg.enable) ''
      # Check if file sharing is enabled
      echo "Checking if file sharing needs to be disabled..."
      SMB_ENABLED=$(sudo defaults read /Library/Preferences/SystemConfiguration/com.apple.services 2>/dev/null | grep -c 'com.apple.smb.server" = 1' || echo "0")
      SMB_RUNNING=$(sudo launchctl list | grep -c com.apple.smbd || echo "0")

      if [ "$SMB_ENABLED" -eq 1 ] || [ "$SMB_RUNNING" -gt 0 ]; then
        echo "Disabling file sharing service..."
        
        # Disable the service in preferences
        sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.services \
          "com.apple.smb.server" -bool false
          
        # Unload the daemon
        sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.smbd.plist
        
        # Remove all shares that we're tracking
        TRACKING_DIR="/var/lib/nix-darwin-shared"
        if [ -d "$TRACKING_DIR" ] && ls "$TRACKING_DIR"/*.share 1> /dev/null 2>&1; then
          echo "Removing tracked shares..."
          for tracking_file in "$TRACKING_DIR"/*.share; do
            if [ -f "$tracking_file" ]; then
              share_name=$(basename "$tracking_file" .share)
              echo "Removing share: $share_name"
              sharing -r "$share_name" 2>/dev/null || echo "Failed to remove share: $share_name"
            fi
          done
          
          echo "Removing tracking directory..."
          sudo rm -rf "$TRACKING_DIR"
        fi
        
        echo "File sharing service has been disabled."
      else
        echo "File sharing service is already disabled."
      fi
    '';
  };
}
