{
  pkgs,
  config,
  ...
}:

# Mac Mini Caddy configuration with waiting for volume mount
# This file provides a backup/resilient web proxy for the homelab
# when the primary proxy (beelink) is unavailable

# KNOWN ISSUE: macOS Sequoia (15.x) has significant problems with Local Network Privacy
# permissions for launchd agents. Even after approving local network access for Caddy:
# 1. The permissions may not apply correctly until a reboot
# 2. The app may lose access after updates or when other apps are launched
# 3. If access problems persist, potential solutions include:
#    - Run as a daemon instead of agent (requires root)
#    - Toggle the Firewall off and on
#    - Manually enable in System Settings → Privacy → Local Network
#
# See: https://mjtsai.com/blog/2024/10/02/local-network-privacy-on-sequoia/
#
# Manually done:
# * Caddy could not connect to local network unless manually approve in security
#
# References:
# * https://apple.stackexchange.com/questions/478037/no-route-to-host-for-certain-applications-from-macos-host-to-macos-guest
# * https://mjtsai.com/blog/2024/10/02/local-network-privacy-on-sequoia/

let
  # Use 0.0.0.0 to listen on all interfaces
  bindAddress = "0.0.0.0";

  # Samsung2TB path for data access
  volumePath = "/Volumes/Samsung2TB";
in
{
  # Configure launchd service for Caddy web server
  launchd.daemons.caddy = {
    serviceConfig = {
      Label = "org.nixos.caddy";
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/tmp/caddy.log";
      StandardErrorPath = "/tmp/caddy.error.log";
      ThrottleInterval = 10; # Restart on failure after 10 seconds
    };

    # Using command instead of ProgramArguments to utilize wait4path
    command =
      let
        # Create the Caddyfile
        caddyfile = pkgs.writeText "Caddyfile" ''
          # Global settings
          {
            auto_https off
            log {
              output file /tmp/caddy-access.log {
                roll_size 10MB
                roll_keep 10
                roll_keep_for 168h
              }
              format json
              level INFO
            }
          }

          # Syncthing hostname for bee
          sync.bee.homelab:80 {
            bind ${bindAddress}

            # Disable TLS
            tls internal

            # Proxy to Syncthing on its configured address
            reverse_proxy ${config.flags.beeIp}:8384
          }

          # Files server for bee (/storage)
          files.bee.homelab:80 {
            bind ${bindAddress}

            # Disable TLS
            tls internal

            # Proxy to local miniserve instance
            reverse_proxy ${config.flags.beeIp}:8080 {
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

          home.bee.homelab:80 {
            bind ${bindAddress}

            # Disable TLS
            tls internal

            # Proxy to Home-Assistant on its configured address
            reverse_proxy ${config.flags.beeIp}:8123
          }

          # Simplified domain for Home Assistant (singleton service)
          homeassistant.homelab:80 {
            bind ${bindAddress}

            # Disable TLS
            tls internal

            # Proxy to Home-Assistant on its configured address
            reverse_proxy ${config.flags.beeIp}:8123
          }

          # Miniserve on Mac mini
          files.mini.homelab:80 {
            bind ${bindAddress}

            # Disable TLS
            tls internal

            # Proxy to miniserve on Mac mini
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

          sync.mini.homelab:80 {
            bind ${bindAddress}

            # Disable TLS
            tls internal

            # Proxy to Syncthing on its configured address
            reverse_proxy 127.0.0.1:8384
          }

          # Prowlarr
          prowlarr.bee.homelab:80 {
            bind ${bindAddress}

            # Disable TLS
            tls internal

            # Proxy to Prowlarr
            reverse_proxy ${config.flags.beeIp}:9696
          }

          # Simplified domain for Prowlarr (singleton service)
          prowlarr.homelab:80 {
            bind ${bindAddress}

            # Disable TLS
            tls internal

            # Proxy to Prowlarr
            reverse_proxy ${config.flags.beeIp}:9696
          }

          # Radarr Web UI
          radarr.bee.homelab:80 {
            bind ${bindAddress}

            # Disable TLS
            tls internal

            # Proxy to Radarr
            reverse_proxy ${config.flags.beeIp}:7878
          }

          # Simplified domain for Radarr (singleton service)
          radarr.homelab:80 {
            bind ${bindAddress}

            # Disable TLS
            tls internal

            # Proxy to Radarr
            reverse_proxy ${config.flags.beeIp}:7878
          }

          # Sonarr Web UI
          sonarr.bee.homelab:80 {
            bind ${bindAddress}
            
            # Disable TLS
            tls internal

            # Proxy to Sonarr
            reverse_proxy ${config.flags.beeIp}:8989
          }

          # Simplified domain for Sonarr (singleton service)
          sonarr.homelab:80 {
            bind ${bindAddress}
            
            # Disable TLS
            tls internal

            # Proxy to Sonarr
            reverse_proxy ${config.flags.beeIp}:8989
          }

          # Transmission Web UI
          transmission.bee.homelab:80 {
            bind ${bindAddress}

            # Disable TLS
            tls internal

            # Proxy to Transmission WebUI
            reverse_proxy ${config.flags.beeIp}:9091
          }

          # Simplified domain for Transmission (singleton service)
          transmission.homelab:80 {
            bind ${bindAddress}

            # Disable TLS
            tls internal

            # Proxy to Transmission WebUI
            reverse_proxy ${config.flags.beeIp}:9091
          }

          # Plex Media Server
          plex.bee.homelab:80 {
            bind ${bindAddress}

            # Disable TLS
            tls internal

            # Proxy to Plex with WebSocket support
            reverse_proxy ${config.flags.beeIp}:32400 {
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
            bind ${bindAddress}

            # Disable TLS
            tls internal

            # Proxy to Plex with WebSocket support
            reverse_proxy ${config.flags.beeIp}:32400 {
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
          netdata.bee.homelab:80 {
            bind ${bindAddress}

            # Disable TLS
            tls internal

            # Proxy to Netdata
            reverse_proxy ${config.flags.beeIp}:19999 {
              # Enable WebSocket support
              header_up X-Real-IP {remote_host}
              header_up Host {host}
            }
          }

          netdata.mini.homelab:80 {
            bind ${bindAddress}

            # Disable TLS
            tls internal

            # FIXME: Should be fixed in nix-darwin or upsteam?
            # Redirect root to v1 dashboard
            redir / /v1/ 302
            redir /index.html /v1/ 302
            
            # Proxy to Netdata
            reverse_proxy 127.0.0.1:19999 {
              # Enable WebSocket support
              header_up X-Real-IP {remote_host}
              header_up Host {host}
            }
          }

          # Grafana
          grafana.bee.homelab:80 {
            bind ${bindAddress}

            # Disable TLS
            tls internal

            # Proxy to Grafana
            reverse_proxy ${config.flags.beeIp}:3000 {
              # Enable WebSocket support
              header_up X-Real-IP {remote_host}
              header_up Host {host}
            }
          }

          # Simplified domain for Grafana (singleton service)
          grafana.homelab:80 {
            bind ${bindAddress}

            # Disable TLS
            tls internal

            # Proxy to Grafana
            reverse_proxy ${config.flags.beeIp}:3000 {
              # Enable WebSocket support
              header_up X-Real-IP {remote_host}
              header_up Host {host}
            }
          }

          # FlareSolverr proxy server
          # flaresolverr.homelab:80 {
          #   bind ${bindAddress}

          #   # Disable TLS
          #   tls internal

          #   # Proxy to FlareSolverr
          #   reverse_proxy 127.0.0.1:8191 {
          #     # Enable WebSocket support
          #     header_up X-Real-IP {remote_host}
          #     header_up Host {host}
          #   }
          # }

          # Audiobookshelf
          audio.bee.homelab:80 {
            bind ${bindAddress}

            # Disable TLS
            tls internal

            # Proxy to Audiobookshelf
            reverse_proxy ${config.flags.beeIp}:8000 {
              # Enable WebSocket support
              header_up X-Real-IP {remote_host}
              header_up Host {host}
            }
          }

          # Simplified domain for Audiobookshelf (singleton service)
          audio.homelab:80 {
            bind ${bindAddress}

            # Disable TLS
            tls internal

            # Proxy to Audiobookshelf
            reverse_proxy ${config.flags.beeIp}:8000 {
              # Enable WebSocket support
              header_up X-Real-IP {remote_host}
              header_up Host {host}
            }
          }
        '';

        # Create the Caddy starter script that waits for the volume
        caddyScript = pkgs.writeShellScriptBin "caddy-starter" ''
          #!/bin/sh

          # Wait for the Samsung2TB volume to be mounted using the built-in wait4path utility
          echo "Waiting for ${volumePath} to be available..."
          /bin/wait4path "${volumePath}"

          echo "${volumePath} is now available!"
          echo "Starting Caddy server..."

          # Store the caddy folder in the home directory
          # Commenting out to test if these are necessary
          # export XDG_CONFIG_HOME="$HOME/.config"
          # export XDG_DATA_HOME="$HOME/.local/share"

          # Make sure the caddy directory exists
          # mkdir -p "$XDG_DATA_HOME/caddy"

          # Launch caddy with our Caddyfile - specifying the caddyfile adapter
          exec ${pkgs.caddy}/bin/caddy run --config ${caddyfile} --adapter=caddyfile
        '';
      in
      "${caddyScript}/bin/caddy-starter";
  };
}
