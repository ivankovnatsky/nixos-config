{
  config,
  lib,
  pkgs,
  ...
}:

let
  setLocalDns = pkgs.writeShellScript "set-local-dns" ''
    set -e

    ${lib.concatMapStringsSep "\n" (
      service: ''/usr/sbin/networksetup -setdnsservers "${service}" 127.0.0.1 1.1.1.1 1.0.0.1''
    ) config.networking.knownNetworkServices}
  '';
in

{
  networking.knownNetworkServices = [
    "AX88179A"
    "Ethernet"
    "Thunderbolt Ethernet Slot 1"
    "Thunderbolt Bridge"
    "Wi-Fi"
  ];
  networking.dns = [
    "127.0.0.1"
    "1.1.1.1"
    "1.0.0.1"
  ];

  sops.secrets.nextdns-endpoint-mini.key = "nextDNS/Mini/dotHostname";
  sops.secrets.nextdns-server-mini-1.key = "nextDNS/Mini/IPs/0";
  sops.secrets.nextdns-server-mini-2.key = "nextDNS/Mini/IPs/1";

  sops.templates."stubby.yml".content = ''
    resolution_type: GETDNS_RESOLUTION_STUB
    dns_transport_list:
      - GETDNS_TRANSPORT_TLS
    tls_authentication: GETDNS_AUTHENTICATION_REQUIRED
    tls_query_padding_blocksize: 128
    round_robin_upstreams: 1
    idle_timeout: 10000
    listen_addresses:
      - ${config.inventory.machineBindAddress}@5453
    upstream_recursive_servers:
      - address_data: ${config.sops.placeholder.nextdns-server-mini-1}
        tls_auth_name: ${config.sops.placeholder.nextdns-endpoint-mini}
      - address_data: ${config.sops.placeholder.nextdns-server-mini-2}
        tls_auth_name: ${config.sops.placeholder.nextdns-endpoint-mini}
  '';

  sops.templates."dnsmasq-domain.conf".content = ''
    domain=${config.sops.placeholder.external-domain}
    local=/${config.sops.placeholder.external-domain}/
    dhcp-option=option:domain-search,${config.sops.placeholder.external-domain}
    address=/${config.sops.placeholder.external-domain}/${config.inventory.miniIp}
    address=/${config.sops.placeholder.external-domain}/${config.inventory.a3Ip}
    mx-host=${config.sops.placeholder.external-domain},${config.sops.placeholder.external-domain},10
  '';

  local.services.stubby = {
    enable = true;
    logLevel = "info";
    configFile = config.sops.templates."stubby.yml".path;
    waitForSecrets = true;
  };

  local.services.dnsmasq = {
    enable = true;
    resolveLocalQueries = false;
    alwaysKeepRunning = true;
    waitForSecrets = true;
    settings = {
      "listen-address" = "0.0.0.0";
      "local-service" = "net";
      "no-resolv" = true;
      server = [
        "127.0.0.1#5453"
        "1.1.1.1"
        "1.0.0.1"
      ];
      "strict-order" = true;
      "max-ttl" = 60;
      "domain-needed" = true;
      "expand-hosts" = true;
      "bogus-priv" = true;
      "dns-forward-max" = 150;
      "conf-file" = [ config.sops.templates."dnsmasq-domain.conf".path ];
    };
  };

  local.launchd.services.dns-ensure = {
    enable = true;
    command = "${setLocalDns}";
    keepAlive = false;
    extraServiceConfig.StartInterval = 60;
  };

  local.launchd.services.dns-cache-flush = {
    enable = true;
    command = "/bin/bash -c 'sleep 2m && /usr/bin/dscacheutil -flushcache && /usr/bin/killall -HUP mDNSResponder'";
    waitForSecrets = false;
    keepAlive = false;
  };

}
