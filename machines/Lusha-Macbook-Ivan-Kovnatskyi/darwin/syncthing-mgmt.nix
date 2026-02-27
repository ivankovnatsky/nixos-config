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
    configDir = "${config.users.users.${username}.home}/Library/Application Support/Syncthing";
    localDeviceName = config.networking.hostName;

    # Device registry (all known devices)
    deviceDefinitionsFile = config.sops.secrets.syncthing-devices.path;

    # Devices this machine connects to
    # Folder device lists use hardcoded hostnames (including self) instead of
    # config.networking.hostName so that machines sharing the same folders can
    # use identical files. Do not replace with config.networking.hostName
    # unless we intentionally want per-machine differences.
    devices = [
      "Lusha-Macbook-Ivan-Kovnatskyi" # This machine (required for local-only folders)
      "a3"
      "Ivans-MacBook-Pro"
      "Ivans-Mac-mini"
      "Ivans-MacBook-Air"
    ];

    # Folders can reference devices by name (resolved from deviceDefinitionsFile)
    folders = {
      "kwhyl-jbqmu" = {
        path = "${config.users.users.${username}.home}/Sources/github.com/NixOS/nixpkgs";
        label = "Sources/github.com/NixOS/nixpkgs";
        devices = [
          "Lusha-Macbook-Ivan-Kovnatskyi"
          "a3"
          "Ivans-MacBook-Pro"
          "Ivans-MacBook-Air"
          "Ivans-Mac-mini"
        ];
      };

      "shtdy-s2c9s" = {
        path = "${config.users.users.${username}.home}/Sources/github.com/ivankovnatsky/nixos-config";
        label = "Sources/github.com/ivankovnatsky/nixos-config";
        devices = [
          "Lusha-Macbook-Ivan-Kovnatskyi"
          "a3"
          "Ivans-MacBook-Pro"
          "Ivans-MacBook-Air"
          "Ivans-Mac-mini"
        ];
      };

      "dotfiles-shared" = {
        path = "${
          config.users.users.${username}.home
        }/Sources/github.com/ivankovnatsky-local/dotfiles-shared";
        label = "Sources/github.com/ivankovnatsky-local/dotfiles-shared";
        devices = [
          "Ivans-MacBook-Pro"
          "Lusha-Macbook-Ivan-Kovnatskyi"
        ];
      };
    };

    restart = false;
  };
}
