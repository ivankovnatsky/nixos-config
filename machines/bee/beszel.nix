{ config, pkgs, ... }:
{
  # Beszel hub migrated to mini
  # Only keep beszel-agent on bee for monitoring

  local.services.beszel-agent = {
    enable = true;
    port = 45876;
    listenAddress = config.flags.beeIp;
    hubPublicKey = config.secrets.beszel.hubPublicKey;
    openFirewall = true;
  };
}
