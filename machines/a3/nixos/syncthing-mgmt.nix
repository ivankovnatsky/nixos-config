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
    configDir = "/home/${username}/.local/state/syncthing";

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
        path = "/home/${username}/Sources";
        label = "Sources";
        devices = [
          "a3"
          "Ivans-Mac-mini"
          "Ivans-MacBook-Pro"
          "Ivans-MacBook-Air"
        ];
      };

      "shtdy-s2c9s" = {
        path = "/home/${username}/Sources/github.com/ivankovnatsky/nixos-config";
        label = "Sources/github.com/ivankovnatsky/nixos-config";
        devices = [
          "a3"
          "Ivans-Mac-mini"
          "Ivans-MacBook-Pro"
          "Lusha-Macbook-Ivan-Kovnatskyi"
        ];
      };

      "kwhyl-jbqmu" = {
        path = "/home/${username}/Sources/github.com/NixOS/nixpkgs";
        label = "Sources/github.com/NixOS/nixpkgs";
        devices = [
          "Lusha-Macbook-Ivan-Kovnatskyi"
        ];
      };

      "nixos-config-ai-docs" = {
        path = "/home/${username}/Sources/github.com/ivankovnatsky/nixos-config-ai-docs";
        label = "Sources/github.com/ivankovnatsky/nixos-config-ai-docs";
        devices = [
          "Lusha-Macbook-Ivan-Kovnatskyi"
        ];
      };

      "ryjnn-fdrug" = {
        path = "/home/${username}/Sources/github.com/ivankovnatsky/notes";
        label = "Sources/github.com/ivankovnatsky/notes";
        devices = [
          "Lusha-Macbook-Ivan-Kovnatskyi"
        ];
      };
    };

    restart = false;
  };
}
