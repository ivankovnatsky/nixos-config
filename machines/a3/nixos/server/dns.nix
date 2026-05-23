{
  config,
  lib,
  pkgs,
  ...
}:

let
  dnsmasqConfPath = config.sops.templates."dnsmasq.conf".path;
  stubbyConfPath = config.sops.templates."stubby.yml".path;
in
{
  sops.secrets.nextdns-endpoint-a3.key = "nextDNS/a3/dotHostname";
  sops.secrets.nextdns-server-a3-1.key = "nextDNS/a3/IPs/0";
  sops.secrets.nextdns-server-a3-2.key = "nextDNS/a3/IPs/1";

  # 0444: upstream services.stubby runs DynamicUser=true, so owner won't
  # stick across boots.
  sops.templates."stubby.yml" = {
    mode = "0444";
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
      upstream_recursive_servers:
        - address_data: ${config.sops.placeholder.nextdns-server-a3-1}
          tls_auth_name: ${config.sops.placeholder.nextdns-endpoint-a3}
        - address_data: ${config.sops.placeholder.nextdns-server-a3-2}
          tls_auth_name: ${config.sops.placeholder.nextdns-endpoint-a3}
    '';
  };

  sops.templates."dnsmasq.conf" = {
    owner = "dnsmasq";
    content = ''
      domain=${config.sops.placeholder.external-domain}
      local=/${config.sops.placeholder.external-domain}/
      dhcp-option=option:domain-search,${config.sops.placeholder.external-domain}
      address=/${config.sops.placeholder.external-domain}/${config.flags.a3Ip}
      mx-host=${config.sops.placeholder.external-domain},${config.sops.placeholder.external-domain},10
    '';
  };

  # Upstream services.stubby has no configFile option and renders
  # cfg.settings into the nix store — which would leak the sops
  # placeholders. Minimal settings here only satisfy the upstream
  # assertion; ExecStart is forced to read the sops-rendered file.
  services.stubby = {
    enable = true;
    settings = {
      resolution_type = "GETDNS_RESOLUTION_STUB";
    };
  };

  systemd.services.stubby = {
    after = [ "sops-nix.service" ];
    wants = [ "sops-nix.service" ];
    serviceConfig.ExecStart = lib.mkForce "${pkgs.stubby}/bin/stubby -C ${stubbyConfPath}";
  };

  services.dnsmasq = {
    enable = true;
    resolveLocalQueries = false;
    settings = {
      listen-address = "127.0.0.1";
      bind-interfaces = true;

      no-resolv = true;
      server = [
        "127.0.0.1#5453"
        "1.1.1.1"
        "1.0.0.1"
      ];
      strict-order = true;

      max-ttl = 60;

      domain-needed = true;
      expand-hosts = true;
      bogus-priv = true;
      dns-forward-max = 150;

      conf-file = [ dnsmasqConfPath ];
    };
  };

  systemd.services.dnsmasq = {
    after = [
      "sops-nix.service"
      "stubby.service"
    ];
    wants = [
      "sops-nix.service"
      "stubby.service"
    ];
  };
}
