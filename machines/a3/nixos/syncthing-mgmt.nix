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

    # API key will be read from config.xml
    apiKeyFile = null;

    # Device registry (all known devices)
    deviceDefinitionsFile = config.sops.secrets.syncthing-devices.path;

    # Devices this machine connects to (auto-includes devices from folders)
    # Only devices referenced in folders will be configured
    devices = [
      "a3" # This machine
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
          "Lusha-Macbook-Ivan-Kovnatskyi"
        ];
      };

      "kwhyl-jbqmu" = {
        path = "${config.users.users.${username}.home}/Sources/github.com/NixOS/nixpkgs";
        label = "Sources/github.com/NixOS/nixpkgs";
        devices = [
          "Lusha-Macbook-Ivan-Kovnatskyi"
        ];
      };

      "ryjnn-fdrug" = {
        path = "${config.users.users.${username}.home}/Sources/github.com/ivankovnatsky/notes";
        label = "Sources/github.com/ivankovnatsky/notes";
        devices = [
          "Lusha-Macbook-Ivan-Kovnatskyi"
        ];
      };

      "simcity4" = {
        path = "${config.users.users.${username}.home}/.local/share/Steam/steamapps/compatdata/24780/pfx/drive_c/users/steamuser/Documents/SimCity 4";
        label = ".local/share/Steam/steamapps/compatdata/24780/pfx/drive_c/users/steamuser/Documents/SimCity 4";
        devices = [
          "a3"
          "Ivans-Mac-mini"
        ];
      };
    };

    restart = false;
  };
}
