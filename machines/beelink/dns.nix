{ config, ... }:
{
  # Enable dnsmasq for local DNS resolution
  services.dnsmasq = {
    enable = true;
    settings = {
      # Listen on specific addresses
      listen-address = "127.0.0.1,192.168.50.169";

      # Don't use /etc/resolv.conf
      no-resolv = true;

      # Use Google DNS as upstream servers
      # Use NextDNS IPs here directly?
      server = config.secrets.nextDnsServers;

      # Set default TTL to 60 seconds
      max-ttl = 60;

      # Local domain configuration
      domain = "home.lan";
      local = "/home.lan/";
      domain-needed = true;
      expand-hosts = true;
      bogus-priv = true;

      # Add search domain for clients
      dhcp-option = "option:domain-search,home.lan";

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
      ];

      # Add wildcard domain support
      address = [
        "/#.beelink.home.lan/192.168.50.169"
      ];

      # Log queries (useful for debugging)
      log-queries = true;
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
