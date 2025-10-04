{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [ ../../../modules/darwin/cloudflared ];

  local.services.cloudflared = {
    enable = true;
    upstreamServers = [
      "https://dns-bee.${config.secrets.externalDomain}/dns-query"
      "https://dns-mini.${config.secrets.externalDomain}/dns-query"
    ];
  };
}
