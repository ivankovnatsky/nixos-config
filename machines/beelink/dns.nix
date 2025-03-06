{
  # Enable dnsmasq for local DNS resolution
  services.dnsmasq = {
    enable = true;
    settings = {
      # Listen on all interfaces
      interface = "";
      bind-interfaces = false;
      listen-address = "127.0.0.1,192.168.50.169";

      # Don't use /etc/resolv.conf
      no-resolv = true;

      # Use Google DNS as upstream servers
      server = [
        # "/home.local/127.0.0.1"
        "/home.local/"
        "8.8.8.8"
        "8.8.4.4"
      ];

      # Local domain configuration
      domain = "home.local";
      local = "/home.local/";
      domain-needed = true;
      expand-hosts = true;
      bogus-priv = true;

      # Make it explicitly authoritative for home.local
      auth-zone = "home.local";
      auth-server = "home.local,192.168.50.169";

      # Local DNS entries - using host-record for better multi-level domain support
      host-record = [
        "sync.beelink.home.local,192.168.50.169"
        "beelink.home.local,192.168.50.169"
      ];

      # Add wildcard domain support
      address = [
        "/#.beelink.home.local/192.168.50.169"
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

  # Add entries to /etc/hosts for local resolution
  networking.extraHosts = ''
    # Local domain entries
    192.168.50.169 sync.beelink.home.local
    192.168.50.169 beelink.home.local
  '';
}
