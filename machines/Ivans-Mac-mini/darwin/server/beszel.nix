{ config, ... }:
{
  local.services.beszel-agent = {
    enable = true;
    port = 45876;
    hubPublicKey = config.secrets.beszel.hubPublicKey;
  };
}
