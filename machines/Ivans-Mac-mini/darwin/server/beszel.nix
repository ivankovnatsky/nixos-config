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
    extraServiceConfig = {
      UserName = "ivan";
      GroupName = "staff";
    };
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
    waitForSecrets = true;
  };

  # Sops secrets for beszel-mgmt
  sops.secrets.beszel-email = {
    key = "beszel/email";
    owner = "ivan";
  };

  sops.secrets.beszel-password = {
    key = "beszel/password";
    owner = "ivan";
  };

  sops.secrets.discord-webhook = {
    key = "discordWebHook";
    owner = "ivan";
  };

  # Beszel management (declarative system sync)
  local.services.beszel-mgmt = {
    enable = true;
    externalDomainFile = config.sops.secrets.external-domain.path;
    emailFile = config.sops.secrets.beszel-email.path;
    passwordFile = config.sops.secrets.beszel-password.path;
    discordWebhookFile = config.sops.secrets.discord-webhook.path;
    systems = [
      {
        name = "Ivans-Mac-mini";
        host = config.flags.miniIp;
        port = "45876";
      }
    ];
  };
}
