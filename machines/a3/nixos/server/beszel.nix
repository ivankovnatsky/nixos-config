{ config, ... }:

{
  # Agent stores the hub's SSH public key it expects inbound SSH connections
  # from. The upstream module reads it from KEY=... in an EnvironmentFile, so
  # wrap the sops secret with a sops template. Quote the value — SSH public
  # keys contain spaces (algo + base64 + optional comment).
  sops.secrets.beszel-hub-public-key = {
    key = "beszel/hubPublicKey";
  };

  sops.templates."beszel-agent.env" = {
    content = ''
      KEY="${config.sops.placeholder.beszel-hub-public-key}"
    '';
    restartUnits = [ "beszel-agent.service" ];
  };

  services.beszel.agent = {
    enable = true;
    openFirewall = true;
    environmentFile = config.sops.templates."beszel-agent.env".path;
  };

  # Hub is fronted by Caddy (beszel.<externalDomain> → a3Ip:8090). Bind 0.0.0.0
  # and open 8090 so the same Caddyfile template works from any host's Caddy.
  services.beszel.hub = {
    enable = true;
    host = "0.0.0.0";
    port = 8090;
  };

  networking.firewall.allowedTCPPorts = [ config.services.beszel.hub.port ];
}
