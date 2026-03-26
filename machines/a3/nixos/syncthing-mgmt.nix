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
    localDeviceName = config.networking.hostName;

    # API key will be read from config.xml
    apiKeyFile = null;

    # Device registry (all known devices)
    deviceDefinitionsFile = config.sops.secrets.syncthing-devices.path;

    # Devices this machine connects to (auto-includes devices from folders)
    # Only devices referenced in folders will be configured
    # Folder device lists use hardcoded hostnames (including self) instead of
    # config.networking.hostName so that machines sharing the same folders can
    # use identical files. Do not replace with config.networking.hostName
    # unless we intentionally want per-machine differences.
    devices = [
      "a3"
      "Ivans-Mac-mini"
      "Ivans-MacBook-Pro"
      "Ivans-MacBook-Air"
      "Lusha-Macbook-Ivan-Kovnatskyi"
    ];

    # Folders can reference devices by name (resolved from deviceDefinitionsFile)
    folders = {
      "simcity4" = {
        path = "${
          config.users.users.${username}.home
        }/.local/share/Steam/steamapps/compatdata/24780/pfx/drive_c/users/steamuser/Documents/SimCity 4";
        label = ".local/share/Steam/steamapps/compatdata/24780/pfx/drive_c/users/steamuser/Documents/SimCity 4";
        devices = [
          "a3"
          "Ivans-Mac-mini"
        ];
      };

      "taskwarrior" = {
        path = "${config.users.users.${username}.home}/.task";
        label = ".task";
        devices = [
          "a3"
          "Ivans-Mac-mini"
          "Ivans-MacBook-Pro"
          "Ivans-MacBook-Air"
        ];
      };

      "nix-config-ignored-files" = {
        path = "${config.users.users.${username}.home}/Sources/github.com/ivankovnatsky/nix-config-ignored-files";
        label = "nix-config-ignored-files";
        devices = [
          "Ivans-Mac-mini"
          "Ivans-MacBook-Pro"
          "Ivans-MacBook-Air"
          "Lusha-Macbook-Ivan-Kovnatskyi"
          "a3"
        ];
      };
    };

    restart = false;
  };
}
