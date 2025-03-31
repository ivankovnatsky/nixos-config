{ config, ... }:
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
      # Syncthing hostname for beelink
      sync.beelink.homelab:80 {
        bind ${config.flags.beelinkIp}

        # Disable TLS
        tls internal

        # Proxy to Syncthing on its configured address
        reverse_proxy ${config.flags.beelinkIp}:8384
      }

      home.beelink.homelab:80 {
        bind ${config.flags.beelinkIp}

        # Disable TLS
        tls internal

        # Proxy to Home-Assistant on its configured address
        reverse_proxy ${config.flags.beelinkIp}:8123
      }

      # Simplified domain for Home Assistant (singleton service)
      homeassistant.homelab:80 {
        bind ${config.flags.beelinkIp}

        # Disable TLS
        tls internal

        # Proxy to Home-Assistant on its configured address
        reverse_proxy ${config.flags.beelinkIp}:8123
      }

      # Miniserve on Mac mini
      files.mini.homelab:80 {
        bind ${config.flags.beelinkIp}

        # Disable TLS
        tls internal
        
        # Proxy to miniserve on Mac mini
        reverse_proxy ${config.flags.macMiniIp}:8080 {
          # Headers for proper operation
          header_up X-Real-IP {remote_host}
          header_up Host {host}
          header_up X-Forwarded-For {remote}
          header_up X-Forwarded-Proto {scheme}
          
          # Increase timeouts and buffer sizes for large directories and files
          transport http {
            keepalive 30s
            response_header_timeout 30s
          }
        }
      }

      sync.mini.homelab:80 {
        bind ${config.flags.beelinkIp}

        # Disable TLS
        tls internal

        # Proxy to Syncthing on its configured address
        reverse_proxy ${config.flags.macMiniIp}:8384
      }

      # Prowlarr
      prowlarr.beelink.homelab:80 {
        bind ${config.flags.beelinkIp}

        # Disable TLS
        tls internal

        # Proxy to Prowlarr
        reverse_proxy 127.0.0.1:9696
      }

      # Simplified domain for Prowlarr (singleton service)
      prowlarr.homelab:80 {
        bind ${config.flags.beelinkIp}

        # Disable TLS
        tls internal

        # Proxy to Prowlarr
        reverse_proxy 127.0.0.1:9696
      }

      # Radarr Web UI
      radarr.beelink.homelab:80 {
        bind ${config.flags.beelinkIp}

        # Disable TLS
        tls internal

        # Proxy to Radarr
        reverse_proxy 127.0.0.1:7878
      }

      # Simplified domain for Radarr (singleton service)
      radarr.homelab:80 {
        bind ${config.flags.beelinkIp}

        # Disable TLS
        tls internal

        # Proxy to Radarr
        reverse_proxy 127.0.0.1:7878
      }

      # Sonarr Web UI
      sonarr.beelink.homelab:80 {
        bind ${config.flags.beelinkIp}
        
        # Disable TLS
        tls internal

        # Proxy to Sonarr
        reverse_proxy 127.0.0.1:8989
      }

      # Simplified domain for Sonarr (singleton service)
      sonarr.homelab:80 {
        bind ${config.flags.beelinkIp}
        
        # Disable TLS
        tls internal

        # Proxy to Sonarr
        reverse_proxy 127.0.0.1:8989
      }

      # Transmission Web UI
      transmission.beelink.homelab:80 {
        bind ${config.flags.beelinkIp}

        # Disable TLS
        tls internal

        # Proxy to Transmission WebUI
        reverse_proxy 127.0.0.1:9091
      }

      # Simplified domain for Transmission (singleton service)
      transmission.homelab:80 {
        bind ${config.flags.beelinkIp}

        # Disable TLS
        tls internal

        # Proxy to Transmission WebUI
        reverse_proxy 127.0.0.1:9091
      }

      # Plex Media Server
      plex.beelink.homelab:80 {
        bind ${config.flags.beelinkIp}

        # Disable TLS
        tls internal

        # Proxy to Plex with WebSocket support
        reverse_proxy 127.0.0.1:32400 {
          # Enable WebSocket support
          header_up X-Real-IP {remote_host}
          header_up Host {host}
          
          # Increase timeouts for streaming
          transport http {
            keepalive 12h
            keepalive_idle_conns 100
          }
        }
      }

      # Simplified domain for Plex (singleton service)
      plex.homelab:80 {
        bind ${config.flags.beelinkIp}

        # Disable TLS
        tls internal

        # Proxy to Plex with WebSocket support
        reverse_proxy 127.0.0.1:32400 {
          # Enable WebSocket support
          header_up X-Real-IP {remote_host}
          header_up Host {host}
          
          # Increase timeouts for streaming
          transport http {
            keepalive 12h
            keepalive_idle_conns 100
          }
        }
      }

      # Netdata
      netdata.beelink.homelab:80 {
        bind ${config.flags.beelinkIp}

        # Disable TLS
        tls internal

        # Proxy to Netdata
        reverse_proxy 127.0.0.1:19999 {
          # Enable WebSocket support
          header_up X-Real-IP {remote_host}
          header_up Host {host}
        }
      }

      netdata.mini.homelab:80 {
        bind ${config.flags.beelinkIp}

        # Disable TLS
        tls internal

        # FIXME: Should be fixed in nix-darwin or upsteam?
        # Redirect root to v1 dashboard
        redir / /v1/ 302
        redir /index.html /v1/ 302
        
        # Proxy to Netdata
        reverse_proxy ${config.flags.macMiniIp}:19999 {
          # Enable WebSocket support
          header_up X-Real-IP {remote_host}
          header_up Host {host}
        }
      }

      # Grafana
      grafana.beelink.homelab:80 {
        bind ${config.flags.beelinkIp}

        # Disable TLS
        tls internal

        # Proxy to Grafana
        reverse_proxy 127.0.0.1:3000 {
          # Enable WebSocket support
          header_up X-Real-IP {remote_host}
          header_up Host {host}
        }
      }

      # Simplified domain for Grafana (singleton service)
      grafana.homelab:80 {
        bind ${config.flags.beelinkIp}

        # Disable TLS
        tls internal

        # Proxy to Grafana
        reverse_proxy 127.0.0.1:3000 {
          # Enable WebSocket support
          header_up X-Real-IP {remote_host}
          header_up Host {host}
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
