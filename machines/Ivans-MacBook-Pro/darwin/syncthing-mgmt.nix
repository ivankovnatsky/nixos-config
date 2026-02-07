{ config, username, ... }:

let homePath = "${config.users.users.${username}.home}";
in
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
    configDir = "${homePath}/Library/Application Support/Syncthing";

    # Device registry (all known devices)
    deviceDefinitionsFile = config.sops.secrets.syncthing-devices.path;

    # Devices this machine connects to (auto-includes devices from folders)
    devices = [
      "Ivans-MacBook-Pro" # This machine (required for local-only folders)

      "a3"
      "Ivans-Mac-mini"
      "Ivans-MacBook-Air"
      "Lusha-Macbook-Ivan-Kovnatskyi"
    ];

    # Folders can reference devices by name (resolved from deviceDefinitionsFile)
    folders = {
      "mqdq9-kaiuw" = {
        path = "${homePath}/.config/rclone";
        label = ".config/rclone";
        devices = [
          "Ivans-Mac-mini"
          "Ivans-MacBook-Air"
        ];
      };

      "qxvnf-blpvx" = {
        path = "${homePath}/.password-store";
        label = ".password-store";
        devices = [
          "Ivans-Mac-mini"
        ];
      };

      "fpbxa-6zw5z" = {
        path = "${homePath}/Sources";
        label = "Sources";
        devices = [
          "Ivans-Mac-mini"
          "Ivans-MacBook-Air"
          "a3"
        ];
      };

      "shtdy-s2c9s" = {
        path = "${homePath}/Sources/github.com/ivankovnatsky/nixos-config";
        label = "Sources/github.com/ivankovnatsky/nixos-config";
        devices = [
          "Ivans-Mac-mini"
          "Ivans-MacBook-Air"
          "Lusha-Macbook-Ivan-Kovnatskyi"
          "a3"
        ];
      };

      "ryjnn-fdrug" = {
        path = "${homePath}/Sources/github.com/ivankovnatsky/notes";
        label = "Sources/github.com/ivankovnatsky/notes";
        devices = [
          "Lusha-Macbook-Ivan-Kovnatskyi"
        ];
      };

      "2z4ss-gffpj" = {
        path = "${homePath}/.gnupg";
        label = "~/.gnupg";
        devices = [ "Ivans-MacBook-Pro" ]; # Local only
      };

      "kwhyl-jbqmu" = {
        path = "${homePath}/Sources/github.com/NixOS/nixpkgs";
        label = "Sources/github.com/NixOS/nixpkgs";
        devices = [
          "Lusha-Macbook-Ivan-Kovnatskyi"
        ];
      };

      "taskwarrior" = {
        path = "${homePath}/.task";
        label = ".task";
        devices = [
          "Ivans-Mac-mini"
          "Ivans-MacBook-Air"
          "a3"
        ];
      };

      "claude-commands" = {
        path = "${homePath}/.claude/commands";
        label = ".claude/commands";
        devices = [
          "Ivans-Mac-mini"
          "Ivans-MacBook-Air"
          "a3"
        ];
      };
    };

    restart = false;
  };
}
