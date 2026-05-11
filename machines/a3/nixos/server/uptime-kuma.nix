{ ... }:

{
  # Uptime Kuma HTTP synthetic monitoring service
  # Web UI exposed via mini's Caddy at https://kuma.@externalDomain@
  # Monitors are reconciled declaratively by the home-manager
  # local.services.uptime-kuma-mgmt service running as user `ivan`.
  #
  # Initial setup: hit the UI once and create the admin account using
  # credentials from sops (uptimeKuma/username, uptimeKuma/password)
  # before the mgmt sync can authenticate.
  services.uptime-kuma = {
    enable = true;
    settings = {
      HOST = "0.0.0.0";
      PORT = "3001";
    };
  };

  networking.firewall.allowedTCPPorts = [ 3001 ];
}
