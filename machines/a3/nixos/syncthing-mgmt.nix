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
    configDir = "${config.users.users.${username}.home}/.local/state/syncthing";
    localDeviceName = config.networking.hostName;

    # API key will be read from config.xml
    apiKeyFile = null;

    # Device registry (all known devices)
    deviceDefinitionsFile = config.sops.secrets.syncthing-devices.path;

    # Devices this machine connects to (auto-includes devices from folders)
    # Only devices referenced in folders will be configured
    # Folder device lists use hardcoded hostnames (including self) instead of
    # config.networking.hostName so that machines sharing the same folders can
    # use identical files. Do not replace with config.networking.hostName
    # unless we intentionally want per-machine differences.
    devices = [
      "a3"
      "Ivans-Mac-mini"
      "Ivans-MacBook-Pro"
      "Ivans-MacBook-Air"
      "Lusha-Macbook-Ivan-Kovnatskyi"
    ];

    # Folders can reference devices by name (resolved from deviceDefinitionsFile)
    folders = {
      "fpbxa-6zw5z" = {
        path = "${config.users.users.${username}.home}/Sources";
        label = "Sources";
        devices = [
          "a3"
          "Ivans-Mac-mini"
          "Ivans-MacBook-Pro"
          "Ivans-MacBook-Air"
        ];
      };

      "shtdy-s2c9s" = {
        path = "${config.users.users.${username}.home}/Sources/github.com/ivankovnatsky/nixos-config";
        label = "Sources/github.com/ivankovnatsky/nixos-config";
        devices = [
          "a3"
          "Ivans-Mac-mini"
          "Ivans-MacBook-Pro"
          "Ivans-MacBook-Air"
          "Lusha-Macbook-Ivan-Kovnatskyi"
        ];
      };

      "kwhyl-jbqmu" = {
        path = "${config.users.users.${username}.home}/Sources/github.com/NixOS/nixpkgs";
        label = "Sources/github.com/NixOS/nixpkgs";
        devices = [
          "a3"
          "Lusha-Macbook-Ivan-Kovnatskyi"
        ];
      };

      "ryjnn-fdrug" = {
        path = "${config.users.users.${username}.home}/Sources/github.com/ivankovnatsky/notes";
        label = "Sources/github.com/ivankovnatsky/notes";
        devices = [
          "a3"
          "Lusha-Macbook-Ivan-Kovnatskyi"
        ];
      };

      "simcity4" = {
        path = "${
          config.users.users.${username}.home
        }/.local/share/Steam/steamapps/compatdata/24780/pfx/drive_c/users/steamuser/Documents/SimCity 4";
        label = ".local/share/Steam/steamapps/compatdata/24780/pfx/drive_c/users/steamuser/Documents/SimCity 4";
        devices = [
          "a3"
          "Ivans-Mac-mini"
        ];
      };

      "liftoff" = {
        path = "${config.users.users.${username}.home}/.config/unity3d/LuGus Studios/Liftoff/RaceTimes";
        label = ".config/unity3d/LuGus Studios/Liftoff/RaceTimes";
        devices = [
          "a3"
          "Ivans-MacBook-Pro"
          "Ivans-MacBook-Air"
        ];
      };

      "taskwarrior" = {
        path = "${config.users.users.${username}.home}/.task";
        label = ".task";
        devices = [
          "a3"
          "Ivans-Mac-mini"
          "Ivans-MacBook-Pro"
          "Ivans-MacBook-Air"
        ];
      };

      "dotfiles" = {
        path = "${config.users.users.${username}.home}/Sources/github.com/ivankovnatsky-local/dotfiles";
        label = "Sources/github.com/ivankovnatsky-local/dotfiles";
        devices = [
          "a3"
          "Ivans-Mac-mini"
          "Ivans-MacBook-Pro"
          "Ivans-MacBook-Air"
        ];
      };

      # WARNING: Source is iCloud-synced Obsidian vault on Air. Only share
      # between Air and a3 — do not add pro or mini.
      "notes" = {
        path = "${config.users.users.${username}.home}/Notes";
        label = "Notes";
        devices = [
          "a3"
          "Ivans-MacBook-Air"
        ];
      };

    };

    restart = false;
  };
}
