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

    # Device registry (all known devices)
    deviceDefinitionsFile = config.sops.secrets.syncthing-devices.path;

    # Devices this machine connects to
    devices = [
      "Lusha-Macbook-Ivan-Kovnatskyi" # This machine (required for local-only folders)
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
          "Ivans-MacBook-Pro"
          "Ivans-MacBook-Air"
          "Ivans-Mac-mini"
        ];
      };

      "nixos-config-ai-docs" = {
        path = "${config.users.users.${username}.home}/Sources/github.com/ivankovnatsky/nixos-config-ai-docs";
        label = "Sources/github.com/ivankovnatsky/nixos-config-ai-docs";
        devices = [
          "Ivans-MacBook-Pro"
          "Ivans-MacBook-Air"
        ];
      };

      "ryjnn-fdrug" = {
        path = "${config.users.users.${username}.home}/Sources/github.com/ivankovnatsky/notes";
        label = "Sources/github.com/ivankovnatsky/notes";
        devices = [
          "Ivans-MacBook-Pro"
          "Ivans-MacBook-Air"
          "Ivans-Mac-mini"
        ];
      };

      "shtdy-s2c9s" = {
        path = "${config.users.users.${username}.home}/Sources/github.com/ivankovnatsky/nixos-config";
        label = "Sources/github.com/ivankovnatsky/nixos-config";
        devices = [
          "Ivans-MacBook-Pro"
          "Ivans-MacBook-Air"
          "Ivans-Mac-mini"
        ];
      };
    };

    restart = false;
  };
}
