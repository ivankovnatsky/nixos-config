{ config, username, ... }:

let
  homePath = "${config.users.users.${username}.home}";
in
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
    configDir = "${homePath}/Library/Application Support/Syncthing";
    localDeviceName = config.networking.hostName;

    # Device registry (all known devices)
    deviceDefinitionsFile = config.sops.secrets.syncthing-devices.path;

    # Devices this machine connects to (auto-includes devices from folders)
    # Folder device lists use hardcoded hostnames (including self) instead of
    # config.networking.hostName so that machines sharing the same folders can
    # use identical files. Do not replace with config.networking.hostName
    # unless we intentionally want per-machine differences.
    devices = [
      "a3"
      "Ivans-Mac-mini"
      "Ivans-MacBook-Air"
      "Ivans-MacBook-Pro"
      "Lusha-Macbook-Ivan-Kovnatskyi"
      "steamdeck"
    ];

    # Folders can reference devices by name (resolved from deviceDefinitionsFile)
    folders = {
      "mqdq9-kaiuw" = {
        path = "${homePath}/.config/rclone";
        label = ".config/rclone";
        devices = [
          "Ivans-Mac-mini"
          "Ivans-MacBook-Air"
          "Ivans-MacBook-Pro"
        ];
      };

      "qxvnf-blpvx" = {
        path = "${homePath}/.password-store";
        label = ".password-store";
        devices = [
          "Ivans-MacBook-Pro"
          "Ivans-MacBook-Air"
          "Ivans-Mac-mini"
        ];
      };

      "2z4ss-gffpj" = {
        path = "${homePath}/.gnupg";
        label = "~/.gnupg";
        devices = [ config.networking.hostName ]; # Local only
      };

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
