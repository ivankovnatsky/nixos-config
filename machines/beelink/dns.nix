{
  config,
  lib,
  ...
}:

{
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
      listen_addresses = [ "127.0.0.1@5453" ];
      upstream_recursive_servers = [
        {
          address_data = lib.elemAt config.secrets.nextDnsServers 0;
          tls_auth_name = config.secrets.nextDnsEndpoint;
        }
        {
          address_data = lib.elemAt config.secrets.nextDnsServers 1;
          tls_auth_name = config.secrets.nextDnsEndpoint;
        }
      ];
    };
  };

  # Enable dnsmasq for local DNS resolution
  services.dnsmasq = {
    enable = true;
    resolveLocalQueries = true;
    alwaysKeepRunning = true;
    settings = {
      # Listen on specific addresses
      listen-address = [
        "127.0.0.1"
        "192.168.50.169"
      ];

      # Don't use /etc/resolv.conf
      no-resolv = true;

      # Use NextDNS servers directly for now
      # server = config.secrets.nextDnsServers;

      # Use stubby as upstream DNS-over-TLS resolver
      server = [ "127.0.0.1#5453" ];

      # Set default TTL to 60 seconds
      max-ttl = 60;

      # Local domain configuration
      domain = "home.lan";
      local = "/home.lan/";
      domain-needed = true;
      expand-hosts = true;
      bogus-priv = true;

      # Add search domain for clients
      dhcp-option = [ "option:domain-search,home.lan" ];

      # Make it explicitly authoritative for home.lan
      auth-zone = "home.lan";
      auth-server = "home.lan";

      # Enable DNS forwarding
      dns-forward-max = 150;

      # Local DNS entries - using host-record for better multi-level domain support
      host-record = [
        "sync.beelink.home.lan,192.168.50.169"
        "sync.pro.home.lan,192.168.50.169"
        "beelink.home.lan,192.168.50.169"
        "plex.beelink.home.lan,192.168.50.169"
        "transmission.beelink.home.lan,192.168.50.169"
        "radarr.beelink.home.lan,192.168.50.169"
        "sonarr.beelink.home.lan,192.168.50.169"
        "prowlarr.beelink.home.lan,192.168.50.169"
        "grafana.beelink.home.lan,192.168.50.169"
        "netdata.beelink.home.lan,192.168.50.169"
        "loki.beelink.home.lan,192.168.50.169"
      ];

      # Add wildcard domain support
      address = [ "/#.beelink.home.lan/192.168.50.169" ];

      # Log queries (useful for debugging)
      log-queries = true;
      log-facility = "/var/log/dnsmasq/dnsmasq.log";
      log-dhcp = true;
    };
  };

  # Open DNS ports in the firewall
  networking.firewall = {
    allowedTCPPorts = [ 53 ];
    allowedUDPPorts = [ 53 ];
    # Ensure the firewall is enabled
    enable = true;
  };
}
