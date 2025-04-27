{ config, pkgs, ... }:

# Obviously DHCP may not assigned the IP yet to a hostname and caddy fails to start:
#
# ```journalctl
# Apr 01 07:13:27 beelink caddy[1835]: Error: loading initial config: loading new config: http app module: start: listening on 192.168.50.3:80: listen tcp 192.168.50.3:80: bind: cannot assign requested address
# Apr 01 07:13:27 beelink systemd[1]: caddy.service: Main process exited, code=exited, status=1/FAILURE
# Apr 01 07:13:27 beelink systemd[1]: caddy.service: Failed with result 'exit-code'.
# ```

# Regarding local domains and SSL certs and CA:
# https://www.reddit.com/r/homelab/comments/z43334/how_to_create_ssl_certs_for_local_domain/?tl=pt-pt
# Using public domains with Let's Encrypt is preferred over creating a local CA (which is complex to setup).
# For local services, it's simpler to buy a cheap domain and use public certs with DNS validation.

# References:
# * https://caddyserver.com/docs/automatic-https#acme-challenges

let
  # IP address to bind services to (all interfaces)
  bindAddress = "0.0.0.0";

  # External domain from secrets module for easier reference
  externalDomain = config.secrets.externalDomain;

  # Create a Caddy package with the required DNS plugin
  # Use the caddy-with-plugins overlay to get the withPlugins functionality
  # This works in NixOS 24.11 before the function is available in the standard package
  caddyWithPlugins = pkgs.caddy-with-plugins.withPlugins {
    # https://github.com/caddy-dns/cloudflare/issues/97#issuecomment-2784508762
    plugins = [ "github.com/caddy-dns/cloudflare@v0.0.0-20250214163716-188b4850c0f2" ];
    hash = "sha256-dYZvFCSuDsOAYg8GgkdpulIzFud9EmP9mS81c87sOoY=";
  };

  # Path to the Caddyfile
  # Using Caddyfile seperately to have a proper formatting to avoid ridiculous
  # warnings and for consistency
  caddyfilePath = ../../templates/Caddyfile;

  # Process the Caddyfile to substitute variables
  Caddyfile =
    pkgs.runCommand "caddyfile"
      {
        inherit bindAddress externalDomain;
        letsEncryptEmail = config.secrets.letsEncryptEmail;
        cloudflareApiToken = config.secrets.cloudflareApiToken;
        beeIp = config.flags.beeIp;
        miniIp = config.flags.miniIp;
        logPathPrefix = "/var/log";
      }
      ''
        substituteAll ${caddyfilePath} $out
      '';
in
{
  # https://github.com/NixOS/nixpkgs/blob/nixos-24.11/nixos/modules/services/web-servers/caddy/default.nix
  # Create the caddy user and group
  users.users.caddy = {
    group = "caddy";
    isSystemUser = true;
    home = "/var/lib/caddy";
    description = "Caddy web server";
  };

  users.groups.caddy = { };

  # Import the systemd units from the caddy package for capabilities
  systemd.packages = [ caddyWithPlugins ];

  # Configure the systemd service
  systemd.services.caddy = {
    description = "Caddy web server";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    # For HTTP/3 high UDP send/receive buffers
    startLimitIntervalSec = 14400;
    startLimitBurst = 10;

    serviceConfig = {
      User = "caddy";
      Group = "caddy";
      # Explicitly specify the caddyfile adapter to ensure proper parsing
      ExecStart = [
        ""
        "${caddyWithPlugins}/bin/caddy run --config ${Caddyfile} --adapter caddyfile"
      ];
      ExecReload = [
        ""
        "${caddyWithPlugins}/bin/caddy reload --config ${Caddyfile} --adapter caddyfile --force"
      ];

      # Directories
      StateDirectory = "caddy";
      LogsDirectory = "caddy";
      ReadWritePaths = [
        "/var/lib/caddy"
        "/var/log/caddy"
      ];

      # Service protection
      Restart = "on-failure";
      RestartSec = "5s";

      # Security hardening
      NoNewPrivileges = true;
      PrivateDevices = true;
      ProtectHome = true;

      # Reload on failure
      RestartPreventExitStatus = 1;
    };
  };

  # https://github.com/quic-go/quic-go/wiki/UDP-Buffer-Sizes
  # For HTTP/3 performance
  boot.kernel.sysctl."net.core.rmem_max" = 2500000;
  boot.kernel.sysctl."net.core.wmem_max" = 2500000;

  # Open HTTP and HTTPS ports in the firewall
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
