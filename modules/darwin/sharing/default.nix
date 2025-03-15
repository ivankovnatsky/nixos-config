{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.macosFileSharing;

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

      guestAccess = mkOption {
        type = types.bool;
        description = "Whether to allow guest access";
        default = false;
      };

      permissions = mkOption {
        type = types.str;
        description = "Permissions for the share in format 'group:permissions'";
        default = "everyone:r,staff:rw";
        example = "everyone:r,staff:rw";
      };
    };
  };
in {
  options.services.macosFileSharing = {
    enable = mkEnableOption "macOS file sharing service";

    shares = mkOption {
      type = types.attrsOf (types.submodule shareOpts);
      default = {};
      description = "Set of shares to configure";
      example = literalExpression ''
        {
          "Media" = {
            path = "/Volumes/ExternalDrive/Media";
            permissions = "everyone:r,staff:rw";
          };
        }
      '';
    };
  };

  config = mkIf cfg.enable {
    system.activationScripts.fileSharingSetup = ''
      echo "Setting up macOS file sharing..."

      # Enable File Sharing in System Settings
      echo "Enabling File Sharing service..."
      sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.smbd.plist
      sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.services \
        "com.apple.smb.server" -bool true

      # Configure shares
      ${concatStringsSep "\n" (mapAttrsToList (name: share: ''
        echo "Configuring share: ${share.name}..."

        # Check if the path exists
        if [ ! -d "${share.path}" ]; then
          echo "Warning: Path ${share.path} does not exist. Share will be created but not active until path exists."
        fi

        # Remove share if it already exists
        if sharing -l | grep -q "name: ${share.name}"; then
          echo "Removing existing share: ${share.name}"
          sharing -r "${share.name}"
        fi

        # Add the share
        sharing -a "${share.path}" -S "${share.name}" -g "${share.permissions}" ${optionalString share.guestAccess "-e"}
      '') cfg.shares)}

      echo "File sharing setup complete."
    '';
  };
}
