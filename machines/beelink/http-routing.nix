{
  # Configure Caddy log directory
  systemd.tmpfiles.rules = [
    "d /var/log/caddy 0755 caddy caddy -"
    "Z /var/log/caddy/* 0644 caddy caddy -"
  ];

  # Enable Caddy web server as a reverse proxy
  services.caddy = {
    enable = true;

    # Ensure Caddy starts after network is up
    enableReload = true;

    # Global settings
    globalConfig = ''
      auto_https off
    '';

    # Define custom log format
    logFormat = ''
      output file /var/log/caddy/beelink.log {
        roll_size 10MB
        roll_keep 10
        roll_keep_for 720h
      }
      format json
      level INFO
    '';

    # Use extraConfig for more direct control over the Caddyfile format
    extraConfig = ''
      # Main landing page for beelink
      # FIXME: Does not work for now yet.
      beelink.homelab:80 {
        bind 192.168.50.169

        # Disable TLS
        tls internal

        # Serve static files from this directory
        root * /var/www/html

        # Enable the static file server
        file_server
      }

      # Syncthing hostname for beelink
      sync.beelink.homelab:80 {
        bind 192.168.50.169

        # Disable TLS
        tls internal

        # Proxy to Syncthing on its configured address
        reverse_proxy 192.168.50.169:8384
      }

      # Syncthing hostname for pro
      sync.pro.homelab:80 {
        bind 192.168.50.169
        
        # Match requests coming from the 50.x network
        @from_50x_network remote_ip 192.168.50.0/24
        
        # For clients on the 50.x network, use the 50.x upstream with redundancy
        reverse_proxy @from_50x_network 192.168.50.243:8384 192.168.0.144:8384 {
          lb_policy first
          lb_try_duration 2s
          header_down +X-Network "50x-network"
          header_down +X-Upstream-Used "{upstream}"
        }
        
        # For all other clients, use the 0.x upstream as primary
        reverse_proxy 192.168.0.144:8384 192.168.50.243:8384 {
          # Add debug info to see what's happening
          header_down +X-Proxied-By "Caddy-Failover"
          header_down +X-Upstream-Used "{upstream}"
          
          # Reduce timeout for faster failover
          # First policy tries first upstream in order (failover)
          lb_policy first
          # Try for 2 seconds to connect to an upstream
          lb_try_duration 2s
          # Check more frequently
          lb_try_interval 100ms
          header_up X-Real-IP {remote_host}
          header_up Host {host}
          header_up X-Forwarded-For {remote_host}
          header_up X-Forwarded-Proto {scheme}
        }
      }

      # Syncthing hostname for air
      sync.air.homelab:80 {
        bind 192.168.50.169
        reverse_proxy 192.168.50.6:8384 {
          header_up X-Real-IP {remote_host}
          header_up Host {host}
          header_up X-Forwarded-For {remote_host}
          header_up X-Forwarded-Proto {scheme}
        }
      }

      # Prowlarr
      prowlarr.beelink.homelab:80 {
        bind 192.168.50.169

        # Disable TLS
        tls internal

        # Proxy to Prowlarr
        reverse_proxy 127.0.0.1:9696
      }

      # Radarr Web UI
      radarr.beelink.homelab:80 {
        bind 192.168.50.169

        # Disable TLS
        tls internal

        # Proxy to Radarr
        reverse_proxy 127.0.0.1:7878
      }

      # Sonarr Web UI
      sonarr.beelink.homelab:80 {
        bind 192.168.50.169
        
        # Disable TLS
        tls internal

        # Proxy to Sonarr
        reverse_proxy 127.0.0.1:8989
      }

      # Transmission Web UI
      transmission.beelink.homelab:80 {
        bind 192.168.50.169

        # Disable TLS
        tls internal

        # Proxy to Transmission WebUI
        reverse_proxy 127.0.0.1:9091
      }

      # Plex Media Server
      plex.beelink.homelab:80 {
        bind 192.168.50.169

        # Disable TLS
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

      # Netdata
      netdata.beelink.homelab:80 {
        bind 192.168.50.169

        # Disable TLS
        tls internal

        # Proxy to Netdata
        reverse_proxy 127.0.0.1:19999 {
          # Enable WebSocket support
          header_up X-Real-IP {remote_host}
          header_up Host {host}
          header_up X-Forwarded-For {remote_host}
          header_up X-Forwarded-Proto {scheme}
        }
      }

      # Grafana
      grafana.beelink.homelab:80 {
        bind 192.168.50.169

        # Disable TLS
        tls internal

        # Proxy to Grafana
        reverse_proxy 127.0.0.1:3000 {
          # Enable WebSocket support
          header_up X-Real-IP {remote_host}
          header_up Host {host}
          header_up X-Forwarded-For {remote_host}
          header_up X-Forwarded-Proto {scheme}
        }
      }
    '';

    # Keep an empty virtualHosts to avoid conflicts
    virtualHosts = { };
  };

  # Open HTTP port in the firewall
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
