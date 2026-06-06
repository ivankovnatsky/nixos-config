{ config, osConfig, ... }:
{
  # Sops secrets for Syncthing management
  sops.secrets = {
    syncthing-devices = {
      key = "syncthing/devices";
    };
  };

  # Syncthing management service
  local.services.syncthing-mgmt = {
    enable = true;
    baseUrl = "http://${config.inventory.machineLocalAddress}:8384";
    configDir = "${config.home.homeDirectory}/Library/Application Support/Syncthing";
    localDeviceName = osConfig.networking.hostName;

    # Device registry (all known devices)
    deviceDefinitionsFile = config.sops.secrets.syncthing-devices.path;

    # Devices this machine connects to (auto-includes devices from folders)
    # Folder device lists use hardcoded hostnames (including self) instead of
    # osConfig.networking.hostName so that machines sharing the same folders can
    # use identical files. Do not replace with osConfig.networking.hostName
    # unless we intentionally want per-machine differences.
    devices = [
      "Ivans-Mac-mini" # This machine
      "a3"
      "Ivans-MacBook-Pro"
      "Ivans-MacBook-Air"
      "Lusha-Macbook-Ivan-Kovnatskyi"
    ];

    # Folders can reference devices by name (resolved from deviceDefinitionsFile)
    folders = {
      "Notes" = {
        path = "${config.home.homeDirectory}/Library/Mobile Documents/iCloud~md~obsidian/Documents/Notes";
        label = "Notes";
        # Apple devices share Notes via iCloud; Syncthing bridges mini to a3.
        devices = [
          "Ivans-Mac-mini"
          "a3"
        ];
        ignorePatterns = [ ".git" ];
      };
    };

    restart = false;
  };
}
