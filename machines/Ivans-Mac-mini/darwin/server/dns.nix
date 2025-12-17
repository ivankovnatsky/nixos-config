{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Configure system to use local dnsmasq as DNS resolver
  networking.knownNetworkServices = [
    "Ethernet"
    "AX88179A"
    "Wi-Fi"
  ];
  networking.dns = [
    "127.0.0.1"
  ];

  # Sops secrets for DNS configuration
  # Note: external-domain is declared in http.nix and beszel.nix (shared across services)
  sops.secrets.nextdns-endpoint-mini.key = "nextDnsEndpointMini";
  sops.secrets.nextdns-server-mini-1.key = "nextDnsServerMini1";
  sops.secrets.nextdns-server-mini-2.key = "nextDnsServerMini2";

  # Sops templates for DNS service configurations
  sops.templates."stubby.yml" = {
    content = ''
      resolution_type: GETDNS_RESOLUTION_STUB
      dns_transport_list:
        - GETDNS_TRANSPORT_TLS
      tls_authentication: GETDNS_AUTHENTICATION_REQUIRED
      tls_query_padding_blocksize: 128
      round_robin_upstreams: 1
      idle_timeout: 10000
      listen_addresses:
        - 127.0.0.1@5453
        - ${config.flags.miniIp}@5453
      upstream_recursive_servers:
        - address_data: ${config.sops.placeholder.nextdns-server-mini-1}
          tls_auth_name: ${config.sops.placeholder.nextdns-endpoint-mini}
        - address_data: ${config.sops.placeholder.nextdns-server-mini-2}
          tls_auth_name: ${config.sops.placeholder.nextdns-endpoint-mini}
    '';
  };

  sops.templates."dnsmasq-domain.conf" = {
    content = ''
      domain=${config.sops.placeholder.external-domain}
      local=/${config.sops.placeholder.external-domain}/
      dhcp-option=option:domain-search,${config.sops.placeholder.external-domain}
      address=/${config.sops.placeholder.external-domain}/${config.flags.miniIp}
    '';
  };

  # Enable stubby for DNS-over-TLS resolution
  local.services.stubby = {
    enable = true;
    logLevel = "info";
    configFile = config.sops.templates."stubby.yml".path;
  };

  # Enable dnsmasq for local DNS resolution
  local.services.dnsmasq = {
    enable = true;
    resolveLocalQueries = true;
    alwaysKeepRunning = true;
    settings = {
      # Listen on specific addresses
      "listen-address" = [
        "127.0.0.1"
        "${config.flags.miniIp}"
      ];

      # Bind to specific interfaces only (prevents binding to 0.0.0.0)
      "bind-interfaces" = true;

      # Don't use /etc/resolv.conf
      "no-resolv" = true;

      # Use stubby as upstream DNS-over-TLS resolver
      server = [ "127.0.0.1#5453" ];

      # Set default TTL to 60 seconds
      "max-ttl" = 60;

      # Domain configuration loaded from sops template
      "domain-needed" = true;
      "expand-hosts" = true;
      "bogus-priv" = true;

      # Enable DNS forwarding
      "dns-forward-max" = 150;

      # Include domain-specific config from sops template
      "conf-file" = [ "${config.sops.templates."dnsmasq-domain.conf".path}" ];

      # Log queries (useful for debugging)
      "log-queries" = true;
      "log-facility" = "/tmp/log/dnsmasq/dnsmasq.log";
      "log-dhcp" = true;
    };
  };
}
