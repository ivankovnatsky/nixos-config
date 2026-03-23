{
  config,
  ...
}:

let
  dnsmasqDomainConfPath = config.sops.templates."dnsmasq-domain.conf".path;
in
{
  # Configure system to use local dnsmasq as DNS resolver
  networking.knownNetworkServices = [
    "AX88179A"
    "Ethernet"
    "Thunderbolt Ethernet Slot 0"
    "Thunderbolt Bridge"
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
        - ${config.flags.machineBindAddress}@5453
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
      address=/${config.sops.placeholder.external-domain}/${config.flags.miniEn7Ip}
      address=/${config.sops.placeholder.external-domain}/${config.flags.miniWifiIp}
      mx-host=${config.sops.placeholder.external-domain},${config.sops.placeholder.external-domain},10
    '';
  };

  # Enable stubby for DNS-over-TLS resolution
  local.services.stubby = {
    enable = true;
    logLevel = "info";
    configFile = config.sops.templates."stubby.yml".path;
    waitForSecrets = true;
  };

  # Enable dnsmasq for local DNS resolution
  local.services.dnsmasq = {
    enable = true;
    resolveLocalQueries = true;
    alwaysKeepRunning = true;
    waitForSecrets = false;
    settings = {
      # Listen on all interfaces (supports both ethernet and WiFi)
      "listen-address" = [
        "127.0.0.1"
        config.flags.miniIp
        config.flags.miniEn7Ip
        config.flags.miniWifiIp
      ];

      # Don't use /etc/resolv.conf
      "no-resolv" = true;

      # Use stubby as primary, with public DNS fallback during boot
      # (before stubby/sops are ready)
      server = [
        "127.0.0.1#5453"
        "1.1.1.1"
        "1.0.0.1"
      ];
      "strict-order" = true;

      # Set default TTL to 60 seconds
      "max-ttl" = 60;

      # Domain configuration loaded from sops template
      "domain-needed" = true;
      "expand-hosts" = true;
      "bogus-priv" = true;

      # Enable DNS forwarding
      "dns-forward-max" = 150;

      # Include domain-specific config from sops template
      "conf-file" = [ "${dnsmasqDomainConfPath}" ];

      # Log queries (useful for debugging)
      "log-queries" = true;
      "log-facility" = "/tmp/log/dnsmasq/dnsmasq.log";
      "log-dhcp" = true;
    };
  };

  # Ensure dnsmasq can start before sops secrets are available
  local.launchd.services.dnsmasq.preStart = ''
    if [ ! -f "${dnsmasqDomainConfPath}" ]; then
      /bin/mkdir -p "$(/usr/bin/dirname "${dnsmasqDomainConfPath}")"
      /usr/bin/touch "${dnsmasqDomainConfPath}"
      echo "$(ts) - INFO - Created empty placeholder for domain config"
      # Restart dnsmasq once real sops config appears
      (
        /bin/wait4path /run/secrets/rendered
        sleep 2
        echo "$(ts) - INFO - Sops secrets available, restarting dnsmasq to load domain config"
        /usr/bin/killall dnsmasq 2>/dev/null || true
      ) &
    fi
  '';
}
