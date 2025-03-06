{
  # Enable Caddy web server as a reverse proxy
  services.caddy = {
    enable = true;

    # Ensure Caddy starts after network is up
    enableReload = true;

    # Global settings
    globalConfig = ''
      auto_https off
    '';

    # Use extraConfig for more direct control over the Caddyfile format
    extraConfig = ''
      # Main landing page for beelink
      # FIXME: Does not work for now yet.
      beelink.home.local:80 {
        bind 192.168.50.169

        # Disable TLS for local development
        tls internal

        # Serve static files from this directory
        root * /var/www/html

        # Enable the static file server
        file_server
      }

      # Syncthing with 4-level domain
      sync.beelink.home.local:80 {
        bind 192.168.50.169
        
        # Disable TLS for local development
        tls internal
        
        # Proxy to Syncthing on its configured address
        reverse_proxy 192.168.50.169:8384
      }
    '';
    
    # Keep an empty virtualHosts to avoid conflicts
    virtualHosts = {};
  };

  # Open HTTP/HTTPS ports in the firewall
  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
