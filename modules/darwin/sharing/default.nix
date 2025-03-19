{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.local.services.macosFileSharing;

  shareOpts = { name, config, ... }: {
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
in {
  options.local.services.macosFileSharing = {
    enable = mkEnableOption "macOS file sharing service";

    shares = mkOption {
      type = types.attrsOf (types.submodule shareOpts);
      default = {};
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

  config = mkIf cfg.enable {
    system.activationScripts.extraActivation.text = ''
      # Basic macOS File Sharing setup
      echo "Setting up macOS file sharing..."

      # Check if file sharing is already enabled
      echo "Checking file sharing service status..."
      SMB_ENABLED=$(sudo defaults read /Library/Preferences/SystemConfiguration/com.apple.services 2>/dev/null | grep -c 'com.apple.smb.server" = 1')
      SMB_RUNNING=$(sudo launchctl list | grep -c com.apple.smbd)
      
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

      # Just check path existence for configured shares
      echo "Checking configured share paths..."
      ${concatStringsSep "\n" (mapAttrsToList (name: share: ''
        # Check if the path exists
        if [ ! -d "${share.path}" ]; then
          echo "Warning: Path ${share.path} does not exist. Would add this volume if it existed."
        else
          echo "Path ${share.path} exists." 
          
          # Capture all existing share information
          SHARE_INFO=$(sharing -l)
          
          # Improved pattern matching to account for variable spacing
          # Check if the path is already shared
          if echo "$SHARE_INFO" | grep "path:" | grep -q "${share.path}"; then
            echo "Path ${share.path} is already shared. Not modifying."
          # Check if the name is already used
          elif echo "$SHARE_INFO" | grep "name:" | grep -q "${share.name}"; then
            echo "Name '${share.name}' is already used for a different share. Not modifying."
          else
            echo "Adding share '${share.name}' for path ${share.path}..."
            # Actually add the share
            sharing -a "${share.path}" -S "${share.name}" || echo "Failed to add share. The name or path might already be shared with different settings."
          fi
        fi
      '') cfg.shares)}
      
      echo "File sharing setup complete."
    '';
  };
}
