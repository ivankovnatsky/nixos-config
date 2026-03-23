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
      "Ivans-MacBook-Air"
    ];

    # Folders can reference devices by name (resolved from deviceDefinitionsFile)
    folders = {
      "nix-config-ignored-files" = {
        path = "/home/${username}/Sources/github.com/ivankovnatsky/nix-config-ignored-files";
        label = "nix-config-ignored-files";
        devices = [
          "Ivans-Mac-mini"
          "Ivans-MacBook-Pro"
          "Ivans-MacBook-Air"
          "Lusha-Macbook-Ivan-Kovnatskyi"
          "a3"
          "steamdeck"
        ];
      };
    };

    restart = false;
  };
}
