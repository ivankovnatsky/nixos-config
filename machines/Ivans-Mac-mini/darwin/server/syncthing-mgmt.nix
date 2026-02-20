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
    baseUrl = "http://${config.flags.machineIp}:8384";
    configDir = "${config.users.users.${username}.home}/Library/Application Support/Syncthing";
    localDeviceName = config.networking.hostName;

    # Device registry (all known devices)
    deviceDefinitionsFile = config.sops.secrets.syncthing-devices.path;

    # Devices this machine connects to (auto-includes devices from folders)
    # Folder device lists use hardcoded hostnames (including self) instead of
    # config.networking.hostName so that machines sharing the same folders can
    # use identical files. Do not replace with config.networking.hostName
    # unless we intentionally want per-machine differences.
    devices = [
      "Ivans-Mac-mini" # This machine
      "a3"
      "Ivans-MacBook-Pro"
      "Ivans-MacBook-Air"
      "Lusha-Macbook-Ivan-Kovnatskyi"
      "steamdeck"
    ];

    # Folders can reference devices by name (resolved from deviceDefinitionsFile)
    folders = {
      "fpbxa-6zw5z" = {
        path = "/Volumes/Storage/Data/Sources";
        label = "Sources";
        devices = [
          "Ivans-Mac-mini"
          "a3"
          "Ivans-MacBook-Pro"
          "steamdeck"
          "Ivans-MacBook-Air"
        ];
      };

      "shtdy-s2c9s" = {
        path = "${config.users.users.${username}.home}/Sources/github.com/ivankovnatsky/nixos-config";
        label = "Sources/github.com/ivankovnatsky/nixos-config";
        devices = [
          "Ivans-Mac-mini"
          "a3"
          "Ivans-MacBook-Pro"
          "Lusha-Macbook-Ivan-Kovnatskyi"
          "steamdeck"
          "Ivans-MacBook-Air"
        ];
      };

      "kwhyl-jbqmu" = {
        path = "/Volumes/Storage/Data/Sources/github.com/NixOS/nixpkgs";
        label = "Sources/github.com/NixOS/nixpkgs";
        devices = [
          "Ivans-Mac-mini"
          "Lusha-Macbook-Ivan-Kovnatskyi"
        ];
      };

      "ryjnn-fdrug" = {
        path = "/Volumes/Storage/Data/Sources/github.com/ivankovnatsky/notes";
        label = "Sources/github.com/ivankovnatsky/notes";
        devices = [
          "Ivans-Mac-mini"
          "Lusha-Macbook-Ivan-Kovnatskyi"
        ];
      };

      "mqdq9-kaiuw" = {
        path = "${config.users.users.${username}.home}/.config/rclone";
        label = ".config/rclone";
        devices = [
          "Ivans-Mac-mini"
          "Ivans-MacBook-Pro"
          "Ivans-MacBook-Air"
        ];
      };

      "qxvnf-blpvx" = {
        path = "${config.users.users.${username}.home}/.password-store";
        label = ".password-store";
        devices = [
          "Ivans-Mac-mini"
          "Ivans-MacBook-Pro"
          "Ivans-MacBook-Air"
        ];
      };

      "simcity4" = {
        path = "/Volumes/Storage/Data/Backup/GameSaves/SimCity4";
        label = "Backup/GameSaves/SimCity4";
        devices = [
          "Ivans-Mac-mini"
          "a3"
        ];
      };

      "taskwarrior" = {
        path = "${config.users.users.${username}.home}/.task";
        label = ".task";
        devices = [
          "Ivans-Mac-mini"
          "Ivans-MacBook-Pro"
          "Ivans-MacBook-Air"
          "a3"
        ];
      };

      "dotfiles" = {
        path = "${config.users.users.${username}.home}/Sources/github.com/ivankovnatsky-local/dotfiles";
        label = "Sources/github.com/ivankovnatsky-local/dotfiles";
        devices = [
          "Ivans-Mac-mini"
          "a3"
          "Ivans-MacBook-Pro"
          "Ivans-MacBook-Air"
        ];
      };

    };

    restart = false;
  };
}
