{ config, ... }:
{
  # Sops secrets for Syncthing management
  sops.secrets = {
    syncthing-api-key-bee = {
      key = "syncthing/apiKeys/bee";
    };
    syncthing-devices = {
      key = "syncthing/devices";
    };
  };

  # Syncthing management service
  local.services.syncthing-mgmt = {
    enable = true;
    baseUrl = "http://${config.flags.beeIp}:8384";
    configDir = config.services.syncthing.configDir;

    # Use API key from secrets
    apiKeyFile = config.sops.secrets.syncthing-api-key-bee.path;

    # Device registry (all known devices)
    deviceDefinitionsFile = config.sops.secrets.syncthing-devices.path;

    # Devices this machine connects to (auto-includes devices from folders)
    devices = [
      "bee" # This machine (required for local-only folders if any)
      "Ivans-Mac-mini"
      "Ivans-MacBook-Air"
      "Ivans-MacBook-Pro"
      "Lusha-Macbook-Ivan-Kovnatskyi"
    ];

    # Folders can reference devices by name (resolved from deviceDefinitionsFile)
    folders = {
      "shtdy-s2c9s" = {
        path = "/home/ivan/Sources/github.com/ivankovnatsky/nixos-config";
        label = "Sources/github.com/ivankovnatsky/nixos-config";
        devices = [
          "Ivans-Mac-mini"
          "Ivans-MacBook-Air"
          "Ivans-MacBook-Pro"
          "Lusha-Macbook-Ivan-Kovnatskyi"
        ];
      };
    };

    restart = false;
  };
}
