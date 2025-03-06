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
      beelink.home.lan:80 {
        bind 192.168.50.169

        # Disable TLS for local development
        tls internal

        # Serve static files from this directory
        root * /var/www/html

        # Enable the static file server
        file_server
      }

      # Syncthing with 4-level domain
      sync.beelink.home.lan:80 {
        bind 192.168.50.169

        # Disable TLS for local development
        tls internal

        # Proxy to Syncthing on its configured address
        reverse_proxy 192.168.50.169:8384
      }

      # Prowlarr
      prowlarr.beelink.home.lan:80 {
        bind 192.168.50.169

        # Disable TLS for local development
        tls internal

        # Proxy to Prowlarr
        reverse_proxy 127.0.0.1:9696
      }

      # Radarr Web UI
      radarr.beelink.home.lan:80 {
        bind 192.168.50.169

        # Disable TLS for local development
        tls internal

        # Proxy to Radarr
        reverse_proxy 127.0.0.1:7878
      }

      # Sonarr Web UI
      sonarr.beelink.home.lan:80 {
        bind 192.168.50.169

        # Disable TLS for local development
        tls internal

        # Proxy to Sonarr
        reverse_proxy 127.0.0.1:8989
      }

      # Transmission Web UI
      transmission.beelink.home.lan:80 {
        bind 192.168.50.169
        
        # Disable TLS for local development
        tls internal

        # Proxy to Transmission WebUI
        reverse_proxy 127.0.0.1:9091
      }

      # Plex Media Server
      plex.beelink.home.lan:80 {
        bind 192.168.50.169
        
        # Disable TLS for local development
        tls internal

        # Proxy to Plex with WebSocket support
        reverse_proxy 127.0.0.1:32400 {
          # Enable WebSocket support
          header_up X-Real-IP {remote_host}
          header_up Host {host}
          header_up X-Forwarded-For {remote_host}
          header_up X-Forwarded-Proto {scheme}
          
          # Increase timeouts for streaming
          transport http {
            keepalive 12h
            keepalive_idle_conns 100
          }
        }
      }
    '';
    
    # Keep an empty virtualHosts to avoid conflicts
    virtualHosts = {};
  };

  # Open HTTP/HTTPS ports in the firewall
  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
