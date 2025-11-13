{ config
, lib
, pkgs
, ...
}:

{
  # Sops secrets for DNS configuration
  # Note: external-domain is declared in sops.nix (shared across services)
  sops.secrets.nextdns-endpoint.key = "nextDnsEndpoint";
  sops.secrets.nextdns-server-1.key = "nextDnsServer1";
  sops.secrets.nextdns-server-2.key = "nextDnsServer2";

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
        - ${config.flags.beeIp}@5453
      upstream_recursive_servers:
        - address_data: ${config.sops.placeholder.nextdns-server-1}
          tls_auth_name: ${config.sops.placeholder.nextdns-endpoint}
        - address_data: ${config.sops.placeholder.nextdns-server-2}
          tls_auth_name: ${config.sops.placeholder.nextdns-endpoint}
    '';
    mode = "0444"; # World-readable
  };

  sops.templates."dnsmasq-domain.conf" = {
    content = ''
      domain=${config.sops.placeholder.external-domain}
      local=/${config.sops.placeholder.external-domain}/
      dhcp-option=option:domain-search,${config.sops.placeholder.external-domain}
      address=/${config.sops.placeholder.external-domain}/${config.flags.beeIp}
    '';
    mode = "0444"; # World-readable
  };

  # Configure dnsmasq user and log directory
  users.groups.dnsmasq = { };
  users.users.dnsmasq = {
    isSystemUser = true;
    group = "dnsmasq";
  };

  systemd.tmpfiles.rules = [
    "d /var/log/dnsmasq 0755 dnsmasq dnsmasq -"
    "Z /var/log/dnsmasq/* 0644 dnsmasq dnsmasq -"
  ];

  # Enable stubby for DNS-over-TLS resolution
  # https://dnsprivacy.org/dns_privacy_daemon_-_stubby/configuring_stubby/
  services.stubby = {
    enable = true;
    logLevel = "info";
    # Minimal settings - actual config generated in preStart from sops
    settings = {
      resolution_type = "GETDNS_RESOLUTION_STUB";
      dns_transport_list = [ "GETDNS_TRANSPORT_TLS" ];
      tls_authentication = "GETDNS_AUTHENTICATION_REQUIRED";
      tls_query_padding_blocksize = 128;
      # duckduckgo.com does not work because of this?
      #
      # ```logs
      # Mar 07 21:38:04 beelink dnsmasq[220827]: query[A] duckduckgo.com from 192.168.50.139
      # Mar 07 21:38:04 beelink dnsmasq[220827]: forwarded duckduckgo.com to 127.0.0.1#5453
      # Mar 07 21:38:04 beelink dnsmasq[220827]: forwarded duckduckgo.com to 127.0.0.1#5453
      # Mar 07 21:38:04 beelink dnsmasq[220827]: reply error is SERVFAIL
      # ```
      #
      # dnssec_return_status = "GETDNS_EXTENSION_TRUE";
      round_robin_upstreams = 1;
      idle_timeout = 10000;
      listen_addresses = [
        "127.0.0.1@5453"
        "${config.flags.beeIp}@5453"
      ];
      # Dummy upstream - will be overridden by runtime config
      upstream_recursive_servers = [
        {
          address_data = "1.1.1.1";
          tls_auth_name = "cloudflare-dns.com";
        }
      ];
    };
  };

  # Override stubby to use sops template config
  systemd.services.stubby.serviceConfig = {
    ExecStart = lib.mkForce "${pkgs.stubby}/bin/stubby -C ${config.sops.templates."stubby.yml".path} -l";
  };

  # Enable dnsmasq for local DNS resolution
  # TODO: DO I need caching?
  services.dnsmasq = {
    enable = true;
    resolveLocalQueries = true;
    alwaysKeepRunning = true;
    settings = {
      # Listen on specific addresses
      listen-address = [
        "127.0.0.1"
        "${config.flags.beeIp}"
      ];

      # Bind to specific interfaces only (prevents binding to 0.0.0.0)
      bind-interfaces = true;

      # Don't use /etc/resolv.conf
      no-resolv = true;

      # Use stubby as upstream DNS-over-TLS resolver
      server = [ "127.0.0.1#5453" ];

      # Set default TTL to 60 seconds
      max-ttl = 60;

      # Domain configuration loaded from sops template
      domain-needed = true;
      expand-hosts = true;
      bogus-priv = true;

      # Enable DNS forwarding
      dns-forward-max = 150;

      # Local DNS entries - using host-record for better multi-level domain support
      host-record = [ ];

      # Include domain-specific config from sops template
      conf-file = [ "${config.sops.templates."dnsmasq-domain.conf".path}" ];

      # Log queries (useful for debugging)
      log-queries = true;
      log-facility = "/var/log/dnsmasq/dnsmasq.log";
      log-dhcp = true;
    };
  };


  # Open DNS ports in the firewall
  networking.firewall = {
    allowedTCPPorts = [
      53 # dnsmasq
      5453 # stubby (DNS-over-TLS)
    ];
    allowedUDPPorts = [
      53 # dnsmasq
      5453 # stubby (DNS-over-TLS)
    ];
    # Ensure the firewall is enabled
    enable = true;
  };

  # Wait for network to be online before starting (DHCP must assign IP first)
  systemd.services.stubby = {
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
  };

  systemd.services.dnsmasq = {
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
  };
}
