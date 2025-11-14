{ config, username, ... }:
{
  # Sops secrets for Syncthing management
  sops.secrets = {
    syncthing-api-key-pro = {
      key = "syncthing/apiKeys/IvansMacBookPro";
      owner = username;
    };
    syncthing-devices = {
      key = "syncthing/devices";
      owner = username;
    };
  };

  # Syncthing management service
  local.services.syncthing-mgmt = {
    enable = true;
    baseUrl = "http://127.0.0.1:8384";
    configDir = "/Users/${username}/Library/Application Support/Syncthing";

    # Use API key from secrets
    apiKeyFile = config.sops.secrets.syncthing-api-key-pro.path;

    # Device registry (all known devices)
    deviceDefinitionsFile = config.sops.secrets.syncthing-devices.path;

    # Devices this machine connects to (auto-includes devices from folders)
    devices = [
      "Ivans-MacBook-Pro" # This machine (required for local-only folders)
      "a3"
      "Ivans-Mac-mini"
      "Ivans-MacBook-Air"
      "Lusha-Macbook-Ivan-Kovnatskyi"
      "steamdeck"
    ];

    # Folders can reference devices by name (resolved from deviceDefinitionsFile)
    folders = {
      "mqdq9-kaiuw" = {
        path = "/Users/${username}/.config/rclone";
        label = ".config/rclone";
        devices = [
          "Ivans-Mac-mini"
          "Ivans-MacBook-Air"
        ];
      };

      "qxvnf-blpvx" = {
        path = "/Users/${username}/.password-store";
        label = ".password-store";
        devices = [
          "Ivans-Mac-mini"
        ];
      };

      "shared-notes" = {
        path = "/Users/${username}/Library/Mobile Documents/com~apple~CloudDocs/Notes/Shared";
        label = "Shared-Notes";
        devices = [ "Ivans-MacBook-Pro" ]; # Local only
      };

      "fpbxa-6zw5z" = {
        path = "/Users/${username}/Sources";
        label = "Sources";
        devices = [
          "a3"
          "Ivans-Mac-mini"
          "steamdeck"
          "Ivans-MacBook-Air"
        ];
      };

      "shtdy-s2c9s" = {
        path = "/Users/${username}/Sources/github.com/ivankovnatsky/nixos-config";
        label = "Sources/github.com/ivankovnatsky/nixos-config";
        devices = [
          "a3"
          "Ivans-Mac-mini"
          "Lusha-Macbook-Ivan-Kovnatskyi"
          "steamdeck"
        ];
      };

      "nixos-config-ai-docs" = {
        path = "/Users/${username}/Sources/github.com/ivankovnatsky/nixos-config-ai-docs";
        label = "Sources/github.com/ivankovnatsky/nixos-config-ai-docs";
        devices = [
          "Lusha-Macbook-Ivan-Kovnatskyi"
        ];
      };

      "ryjnn-fdrug" = {
        path = "/Users/${username}/Sources/github.com/ivankovnatsky/notes";
        label = "Sources/github.com/ivankovnatsky/notes";
        devices = [
          "Lusha-Macbook-Ivan-Kovnatskyi"
        ];
      };

      "2z4ss-gffpj" = {
        path = "/Users/${username}/.gnupg";
        label = "~/.gnupg";
        devices = [ "Ivans-MacBook-Pro" ]; # Local only
      };
    };

    restart = false;
  };
}
