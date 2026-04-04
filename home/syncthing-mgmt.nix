{ config, osConfig, ... }:

let
  homePath = config.home.homeDirectory;
in
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
    configDir = "${homePath}/Library/Application Support/Syncthing";
    localDeviceName = osConfig.networking.hostName;

    # Device registry (all known devices)
    deviceDefinitionsFile = config.sops.secrets.syncthing-devices.path;

    # Devices this machine connects to (auto-includes devices from folders)
    # Folder device lists use hardcoded hostnames (including self) instead of
    # osConfig.networking.hostName so that machines sharing the same folders can
    # use identical files. Do not replace with osConfig.networking.hostName
    # unless we intentionally want per-machine differences.
    devices = [
      "a3"
      "Ivans-Mac-mini"
      "Ivans-MacBook-Air"
      "Ivans-MacBook-Pro"
      "Lusha-Macbook-Ivan-Kovnatskyi"
    ];

    # Folders can reference devices by name (resolved from deviceDefinitionsFile)
    folders = {
      "taskwarrior" = {
        path = "${homePath}/.task";
        label = ".task";
        devices = [
          "Ivans-Mac-mini"
          "Ivans-MacBook-Pro"
          "Ivans-MacBook-Air"
          "a3"
        ];
      };
    };
    restart = false;
  };
}
