{ config, pkgs, username, ... }:

let
  dataDir = "${config.flags.miniStoragePath}/.beszel-hub";
in
{
  # Beszel Hub service - user-agent to access /Volumes/Storage after login
  # See: claude/issues/LAUNCHD-BOOT-FAILURE.md
  # Manual restart: launchctl kickstart -k gui/$(id -u)/com.ivankovnatsky.beszel-hub
  local.launchd.services.beszel-hub = {
    enable = true;
    type = "user-agent";
    waitForPath = config.flags.miniStoragePath;
    dataDir = dataDir;
    command = ''
      ${pkgs.nixpkgs-darwin-master.beszel}/bin/beszel-hub serve \
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
    package = pkgs.nixpkgs-darwin-master.beszel;
    port = 45876;
    listenAddress = config.flags.miniIp;
    hubPublicKeyFile = config.sops.secrets.beszel-hub-public-key.path;
    waitForSecrets = true;
  };

  # Sops secrets for beszel-mgmt
  sops.secrets.beszel-email = {
    key = "beszel/email";
    owner = username;
  };

  sops.secrets.beszel-password = {
    key = "beszel/password";
    owner = username;
  };

  sops.secrets.discord-webhook = {
    key = "discordWebHook";
    owner = username;
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
