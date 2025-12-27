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
    baseUrl = "http://192.168.50.4:8384";
    configDir = "${config.users.users.${username}.home}/Library/Application Support/Syncthing";
    localDeviceName = "Ivans-Mac-mini";

    # Device registry (all known devices)
    deviceDefinitionsFile = config.sops.secrets.syncthing-devices.path;

    # Devices this machine connects to (auto-includes devices from folders)
    devices = [
      "Ivans-Mac-mini" # This machine
      "a3"
      "Ivans-MacBook-Pro"
      "Ivans-MacBook-Air"
      "Lusha-Macbook-Ivan-Kovnatskyi"
    ];

    # Folders can reference devices by name (resolved from deviceDefinitionsFile)
    folders = {
      "fpbxa-6zw5z" = {
        path = "/Volumes/Storage/Data/Sources";
        label = "Sources";
        devices = [
          "a3"
          "Ivans-MacBook-Pro"
          "Ivans-MacBook-Air"
        ];
      };

      "shtdy-s2c9s" = {
        path = "${config.users.users.${username}.home}/Sources/github.com/ivankovnatsky/nixos-config";
        label = "Sources/github.com/ivankovnatsky/nixos-config";
        devices = [
          "a3"
          "Ivans-MacBook-Pro"
          "Lusha-Macbook-Ivan-Kovnatskyi"
          "Ivans-MacBook-Air"
        ];
      };

      "kwhyl-jbqmu" = {
        path = "/Volumes/Storage/Data/Sources/github.com/NixOS/nixpkgs";
        label = "Sources/github.com/NixOS/nixpkgs";
        devices = [
          "Lusha-Macbook-Ivan-Kovnatskyi"
        ];
      };

      "ryjnn-fdrug" = {
        path = "/Volumes/Storage/Data/Sources/github.com/ivankovnatsky/notes";
        label = "Sources/github.com/ivankovnatsky/notes";
        devices = [
          "Lusha-Macbook-Ivan-Kovnatskyi"
        ];
      };

      "mqdq9-kaiuw" = {
        path = "${config.users.users.${username}.home}/.config/rclone";
        label = ".config/rclone";
        devices = [
          "Ivans-MacBook-Pro"
          "Ivans-MacBook-Air"
        ];
      };

      "qxvnf-blpvx" = {
        path = "${config.users.users.${username}.home}/.password-store";
        label = ".password-store";
        devices = [
          "Ivans-MacBook-Pro"
          "Ivans-MacBook-Air"
        ];
      };

      "simcity4" = {
        path = "/Volumes/Storage/Data/Backup/GameSaves/SimCity4";
        label = "Backup/GameSaves/SimCity4";
        devices = [
          "a3"
        ];
      };

      "taskwarrior" = {
        path = "${config.users.users.${username}.home}/.task";
        label = ".task";
        devices = [
          "Ivans-MacBook-Pro"
          "Ivans-MacBook-Air"
          "a3"
        ];
      };

    };

    restart = false;
  };
}
