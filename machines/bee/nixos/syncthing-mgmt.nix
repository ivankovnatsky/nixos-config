{ config, ... }:
{
  # Sops secrets for Syncthing management
  sops.secrets = {
    syncthing-gui-username.key = "syncthing/credentials/username";
    syncthing-gui-password.key = "syncthing/credentials/hashedPassword";
    syncthing-devices.key = "syncthing/devices";
  };

  # Syncthing management service
  local.services.syncthing-mgmt = {
    enable = true;
    baseUrl = "http://${config.flags.beeIp}:8384";
    configDir = config.services.syncthing.configDir;

    gui = {
      usernameFile = config.sops.secrets.syncthing-gui-username.path;
      passwordFile = config.sops.secrets.syncthing-gui-password.path;
    };

    devicesFile = config.sops.secrets.syncthing-devices.path;

    # Folders can reference devices by name (resolved from devicesFile)
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
