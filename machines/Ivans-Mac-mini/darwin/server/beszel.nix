{ config, pkgs, ... }:

let
  dataDir = "${config.flags.miniStoragePath}/.beszel-hub";
in
{
  # Beszel Hub service
  # Note: Requires Full Disk Access in System Settings → Privacy & Security
  # to write to /Volumes/Storage (granted manually, testing if works)
  #
  # Manual restart: sudo launchctl kickstart -k system/org.nixos.beszel-hub
  local.launchd.services.beszel-hub = {
    enable = true;
    type = "daemon";
    waitForPath = config.flags.miniStoragePath;
    dataDir = dataDir;
    command = ''
      ${pkgs.nixpkgs-master.beszel}/bin/beszel-hub serve \
        --http ${config.flags.miniIp}:8091 \
        --dir ${dataDir}
    '';
  };

  # Beszel Agent (monitoring mini itself)
  sops.secrets.beszel-hub-public-key = {
    key = "beszel/hubPublicKey";
  };

  local.services.beszel-agent = {
    enable = true;
    package = pkgs.nixpkgs-master.beszel;
    port = 45876;
    listenAddress = config.flags.miniIp;
    hubPublicKeyFile = config.sops.secrets.beszel-hub-public-key.path;
  };

  # Beszel management (declarative system sync)
  local.services.beszel-mgmt = {
    enable = true;
    email = config.secrets.beszel.email;
    password = config.secrets.beszel.password;
    discordWebhook = config.secrets.discordWebHook;
    systems = [
      {
        name = "bee";
        host = config.flags.beeIp;
        port = "45876";
      }
      {
        name = "Ivans-Mac-mini";
        host = config.flags.miniIp;
        port = "45876";
      }
    ];
  };
}
