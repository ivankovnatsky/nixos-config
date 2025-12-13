{ config, username, ... }:
{
  # Sops secrets for Syncthing management
  sops.secrets = {
    syncthing-devices = {
      key = "syncthing/devices";
      owner = username;
    };
  };

  # Syncthing management service
  local.services.syncthing-mgmt = {
    enable = true;
    baseUrl = "http://127.0.0.1:8384";
    configDir = "/Users/${username}/Library/Application Support/Syncthing";

    # Device registry (all known devices)
    deviceDefinitionsFile = config.sops.secrets.syncthing-devices.path;

    # Devices this machine connects to (auto-includes devices from folders)
    devices = [
      "Ivans-MacBook-Air" # This machine (required for local-only folders)
      "Ivans-MacBook-Pro"
      "a3"
      "Lusha-Macbook-Ivan-Kovnatskyi"
    ];

    # Folders can reference devices by name (resolved from deviceDefinitionsFile)
    folders = {
      "mqdq9-kaiuw" = {
        path = "/Users/${username}/.config/rclone";
        label = ".config/rclone";
        devices = [
          "Ivans-MacBook-Pro"
        ];
      };

      "shared-notes" = {
        path = "/Users/${username}/Library/Mobile Documents/com~apple~CloudDocs/Notes/Shared";
        label = "Shared-Notes";
        devices = [ "Ivans-MacBook-Air" ]; # Local only
      };

      "fpbxa-6zw5z" = {
        path = "/Users/${username}/Sources";
        label = "Sources";
        devices = [
          "Ivans-MacBook-Pro"
          "a3"
        ];
      };

      "2z4ss-gffpj" = {
        path = "/Users/${username}/.gnupg";
        label = "~/.gnupg";
        devices = [ "Ivans-MacBook-Air" ]; # Local only
      };

      "kwhyl-jbqmu" = {
        path = "/Users/${username}/Sources/github.com/NixOS/nixpkgs";
        label = "Sources/github.com/NixOS/nixpkgs";
        devices = [
          "Lusha-Macbook-Ivan-Kovnatskyi"
        ];
      };

      "ryjnn-fdrug" = {
        path = "/Users/${username}/Sources/github.com/ivankovnatsky/notes";
        label = "Sources/github.com/ivankovnatsky/notes";
        devices = [
          "Lusha-Macbook-Ivan-Kovnatskyi"
        ];
      };

      "qxvnf-blpvx" = {
        path = "/Users/${username}/.password-store";
        label = "~/.password-store";
        devices = [
          "Ivans-MacBook-Air" # Local only
        ];
      };

      "shtdy-s2c9s" = {
        path = "/Users/${username}/Sources/github.com/ivankovnatsky/nixos-config";
        label = "Sources/github.com/ivankovnatsky/nixos-config";
        devices = [
          "Lusha-Macbook-Ivan-Kovnatskyi"
        ];
      };
    };

    restart = false;
  };
}
