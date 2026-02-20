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
      "steamdeck" # This machine
      "a3"
      "Ivans-Mac-mini"
      "Ivans-MacBook-Pro"
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
          "steamdeck"
        ];
      };

      "shtdy-s2c9s" = {
        path = "/home/${username}/Sources/github.com/ivankovnatsky/nixos-config";
        label = "Sources/github.com/ivankovnatsky/nixos-config";
        devices = [
          "a3"
          "Ivans-Mac-mini"
          "Ivans-MacBook-Pro"
          "steamdeck"
        ];
      };
    };

    restart = false;
  };
}
