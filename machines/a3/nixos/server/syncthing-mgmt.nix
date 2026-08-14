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
      "Ivans-iPhone"
      "Ivans-Mac-mini"
      "Ivans-MacBook-Pro"
      "Ivans-MacBook-Air"
      "Canaris-iPhone"
    ];

    # Folders can reference devices by name (resolved from deviceDefinitionsFile)
    folders = {
      "Notes" = {
        path = "${config.users.users.${username}.home}/Notes";
        label = "Notes";
        # reposync owns the git history; Syncthing carries the working tree only.
        # Pro/Air sync Notes via iCloud + Unison instead of Syncthing;
        # the mini is the bridge from that iCloud world into Syncthing.
        devices = [
          "a3"
          "Ivans-Mac-mini"
        ];
        ignorePatterns = [
          ".git"
          ".claude"
          ".rumdl_cache"
        ];
      };
      "Notes2" = {
        path = "${config.users.users.${username}.home}/Notes2";
        label = "Notes2";
        devices = [
          "a3"
          "Ivans-Mac-mini"
          "Canaris-iPhone"
        ];
        ignorePatterns = [
          ".git"
          ".claude"
          ".rumdl_cache"
        ];
      };
    };

    restart = false;
  };
}
