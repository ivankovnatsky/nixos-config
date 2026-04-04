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
    baseUrl = "http://127.0.0.1:8384";
    configDir = "${config.home.homeDirectory}/Library/Application Support/Syncthing";
    localDeviceName = osConfig.networking.hostName;

    # Device registry (all known devices)
    deviceDefinitionsFile = config.sops.secrets.syncthing-devices.path;

    # Devices this machine connects to
    # Folder device lists use hardcoded hostnames (including self) instead of
    # osConfig.networking.hostName so that machines sharing the same folders can
    # use identical files. Do not replace with osConfig.networking.hostName
    # unless we intentionally want per-machine differences.
    devices = [
      "Lusha-Macbook-Ivan-Kovnatskyi" # This machine (required for local-only folders)
      "a3"
      "Ivans-MacBook-Pro"
      "Ivans-Mac-mini"
      "Ivans-MacBook-Air"
    ];

    # Folders can reference devices by name (resolved from deviceDefinitionsFile)
    folders = { };

    restart = false;
  };
}
