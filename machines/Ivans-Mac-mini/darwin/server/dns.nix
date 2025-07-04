{
  config,
  lib,
  ...
}:

{
  # Enable stubby for DNS-over-TLS resolution
  local.services.stubby = {
    enable = true;
    logLevel = "info";
    settings = {
      resolution_type = "GETDNS_RESOLUTION_STUB";
      dns_transport_list = [ "GETDNS_TRANSPORT_TLS" ];
      tls_authentication = "GETDNS_AUTHENTICATION_REQUIRED";
      tls_query_padding_blocksize = 128;
      # dnssec_return_status = "GETDNS_EXTENSION_TRUE";
      round_robin_upstreams = 1;
      idle_timeout = 10000;
      listen_addresses = [
        "127.0.0.1@5453"
        "${config.flags.miniIp}@5453"
      ];
      upstream_recursive_servers = [
        {
          address_data = lib.elemAt config.secrets.nextDnsServersMini 0;
          tls_auth_name = config.secrets.nextDnsEndpointMini;
        }
        {
          address_data = lib.elemAt config.secrets.nextDnsServersMini 1;
          tls_auth_name = config.secrets.nextDnsEndpointMini;
        }
      ];
    };
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

      # Don't use /etc/resolv.conf
      "no-resolv" = true;

      # Use stubby as upstream DNS-over-TLS resolver
      server = [ "127.0.0.1#5453" ];

      # Set default TTL to 60 seconds
      "max-ttl" = 60;

      # Local domain configuration
      domain = "${config.secrets.externalDomain}";
      local = "/${config.secrets.externalDomain}/";
      "domain-needed" = true;
      "expand-hosts" = true;
      "bogus-priv" = true;

      # Add search domain for clients
      "dhcp-option" = [ "option:domain-search,${config.secrets.externalDomain}" ];

      # Enable DNS forwarding
      "dns-forward-max" = 150;

      # Wildcard domain support
      # We host caddy on the same machine, thus we need to resolve external domain to
      # the same machine IP, and it's up for caddy to do the routing.
      address = [
        "/${config.secrets.externalDomain}/${config.flags.miniIp}" # This will match all *.externalDomain records
      ];

      # Log queries (useful for debugging)
      "log-queries" = true;
      "log-facility" = "/tmp/log/dnsmasq/dnsmasq.log";
      "log-dhcp" = true;
    };
  };
}
