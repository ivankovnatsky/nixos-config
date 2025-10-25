{ config, pkgs, ... }:
{
  # Beszel hub migrated to mini
  # Only keep beszel-agent on bee for monitoring

  sops.defaultSopsFile = ../../../secrets/default.yaml;
  sops.secrets.beszel-hub-public-key = {
    key = "beszel/hubPublicKey";
  };

  local.services.beszel-agent = {
    enable = true;
    port = 45876;
    listenAddress = config.flags.beeIp;
    hubPublicKeyFile = config.sops.secrets.beszel-hub-public-key.path;
    openFirewall = true;
  };
}
