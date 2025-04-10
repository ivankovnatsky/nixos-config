{ config, pkgs, ... }:

# Obviously DHCP may not assigned the IP yet to a hostname and caddy fails to start:
#
# ```journalctl
# Apr 01 07:13:27 beelink caddy[1835]: Error: loading initial config: loading new config: http app module: start: listening on 192.168.50.3:80: listen tcp 192.168.50.3:80: bind: cannot assign requested address
# Apr 01 07:13:27 beelink systemd[1]: caddy.service: Main process exited, code=exited, status=1/FAILURE
# Apr 01 07:13:27 beelink systemd[1]: caddy.service: Failed with result 'exit-code'.
# ```

# Regarding local domains and SSL certs and CA:
# https://www.reddit.com/r/homelab/comments/z43334/how_to_create_ssl_certs_for_local_domain/?tl=pt-pt
# Using public domains with Let's Encrypt is preferred over creating a local CA (which is complex to setup).
# For local services, it's simpler to buy a cheap domain and use public certs with DNS validation.

# References:
# * https://caddyserver.com/docs/automatic-https#acme-challenges

let
  # IP address to bind services to (all interfaces)
  bindAddress = "0.0.0.0";

  # External domain from secrets module for easier reference
  externalDomain = config.secrets.externalDomain;

in
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

    # Use the caddy-with-plugins overlay to get the withPlugins functionality
    # This works in NixOS 24.11 before the function is available in the standard package
    package = pkgs.caddy-with-plugins.withPlugins {
      # https://github.com/caddy-dns/cloudflare/issues/97#issuecomment-2784508762
      plugins = [ "github.com/caddy-dns/cloudflare@v0.0.0-20250214163716-188b4850c0f2" ];
      hash = "sha256-dYZvFCSuDsOAYg8GgkdpulIzFud9EmP9mS81c87sOoY=";
    };

    # Global settings
    # https://caddyserver.com/docs/caddyfile/options
    globalConfig = ''
      # Global settings

      # Configure ACME for external domains
      email ${config.secrets.letsEncryptEmail}

      # Default ACME configuration - use cloudflare DNS challenge globally
      acme_dns cloudflare ${config.secrets.cloudflareApiToken}
    '';

    # Custom log format
    logFormat = ''
      output file /var/log/caddy/caddy.log {
        roll_size 10MB
        roll_keep 10
        roll_keep_for 48h
      }
      format json
      level INFO
    '';

    # Use extraConfig for more direct control over the Caddyfile format
    extraConfig = ''
      # Syncthing with registered domain and proper SSL
      # Use *.externalDomain to request a wildcard certificate
      *.${externalDomain}:443 {
        bind ${bindAddress}

        # Enable proper TLS with Let's Encrypt using DNS challenge for wildcard cert
        # https://caddyserver.com/docs/automatic-https#wildcard-certificates
        # https://caddy.community/t/how-to-use-dns-provider-modules-in-caddy-2/8148
        tls {
          dns cloudflare ${config.secrets.cloudflareApiToken}
          # Use external DNS resolvers for ACME challenges
          # https://caddy.community/t/could-not-determine-zone-for-domain/18720/7
          resolvers 1.1.1.1 8.8.8.8
        }

        reverse_proxy ${config.flags.beeIp}:80

        # Log ACME challenges for debugging
        log {
          output file /var/log/caddy/acme-sync.log {
            roll_size 10MB
            roll_keep 5
          }
        }
      }

      # Specific site for sync-bee.externalDomain
      sync-bee.${externalDomain}:443 {
        bind ${bindAddress}

        # Proxy to Syncthing
        reverse_proxy ${config.flags.beeIp}:8384
      }

      # Files server for bee
      files-bee.${externalDomain}:443 {
        bind ${bindAddress}

        # Proxy to local miniserve instance
        reverse_proxy 127.0.0.1:8080 {
          # Headers for proper operation
          header_up X-Real-IP {remote_host}
          header_up Host {host}

          # Increase timeouts and buffer sizes for large directories and files
          transport http {
            keepalive 30s
            response_header_timeout 30s
          }
        }
      }

      # Simplified domain for Home Assistant (singleton service)
      homeassistant.${externalDomain}:443 {
        bind ${bindAddress}

        # Proxy to Home-Assistant on its configured address
        reverse_proxy ${config.flags.beeIp}:8123
      }

      # Miniserve on Mac mini
      files-mini.${externalDomain}:443 {
        bind ${bindAddress}

        # Proxy to miniserve on Mac mini
        reverse_proxy ${config.flags.miniIp}:8080 {
          # Headers for proper operation
          header_up X-Real-IP {remote_host}
          header_up Host {host}

          # Increase timeouts and buffer sizes for large directories and files
          transport http {
            keepalive 30s
            response_header_timeout 30s
          }
        }
      }

      sync-mini.${externalDomain}:443 {
        bind ${bindAddress}

        # Proxy to Syncthing on its configured address
        reverse_proxy ${config.flags.miniIp}:8384
      }

      # Simplified domain for Prowlarr (singleton service)
      prowlarr.${externalDomain}:443 {
        bind ${bindAddress}

        # Proxy to Prowlarr
        reverse_proxy 127.0.0.1:9696
      }

      # Simplified domain for Radarr (singleton service)
      radarr.${externalDomain}:443 {
        bind ${bindAddress}

        # Proxy to Radarr
        reverse_proxy 127.0.0.1:7878
      }

      # Simplified domain for Sonarr (singleton service)
      sonarr.${externalDomain}:443 {
        bind ${bindAddress}
        
        # Proxy to Sonarr
        reverse_proxy 127.0.0.1:8989
      }

      # Simplified domain for Transmission (singleton service)
      transmission.${externalDomain}:443 {
        bind ${bindAddress}

        # Proxy to Transmission WebUI
        reverse_proxy 127.0.0.1:9091
      }

      # Simplified domain for Plex (singleton service)
      plex.${externalDomain}:443 {
        bind ${bindAddress}

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
      netdata-bee.${externalDomain}:443 {
        bind ${bindAddress}

        # Proxy to Netdata
        reverse_proxy 127.0.0.1:19999 {
          # Enable WebSocket support
          header_up X-Real-IP {remote_host}
          header_up Host {host}
        }
      }

      netdata-mini.${externalDomain} {
        bind ${bindAddress}

        # FIXME: Should be fixed in nix-darwin or upsteam?
        # Redirect root to v1 dashboard
        redir / /v1/ 302
        redir /index.html /v1/ 302
        
        # Proxy to Netdata
        reverse_proxy ${config.flags.miniIp}:19999 {
          # Enable WebSocket support
          header_up X-Real-IP {remote_host}
          header_up Host {host}
        }
      }

      # Simplified domain for Grafana (singleton service)
      grafana.${externalDomain} {
        bind ${bindAddress}

        # Proxy to Grafana
        reverse_proxy 127.0.0.1:3000 {
          # Enable WebSocket support
          header_up X-Real-IP {remote_host}
          header_up Host {host}
        }
      }

      # FlareSolverr proxy server
      # flaresolverr.${externalDomain} {
      #   bind ${bindAddress}

      #   # Proxy to FlareSolverr
      #   reverse_proxy 127.0.0.1:8191 {
      #     # Enable WebSocket support
      #     header_up X-Real-IP {remote_host}
      #     header_up Host {host}
      #   }
      # }

      # Simplified domain for Audiobookshelf (singleton service)
      audiobookshelf.${externalDomain} {
        bind ${bindAddress}

        # Proxy to Audiobookshelf
        reverse_proxy 127.0.0.1:8000 {
          # Enable WebSocket support
          header_up X-Real-IP {remote_host}
          header_up Host {host}
        }
      }

      # Simplified domain for Jellyfin (singleton service)
      jellyfin.${externalDomain} {
        bind ${bindAddress}

        # Proxy to Jellyfin
        reverse_proxy 127.0.0.1:8096 {
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
    '';

    # Keep an empty virtualHosts to avoid conflicts
    virtualHosts = { };
  };

  # Open HTTP and HTTPS ports in the firewall
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
