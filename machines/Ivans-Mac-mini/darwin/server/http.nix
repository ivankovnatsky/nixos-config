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
  bindAddress = config.flags.miniIp;

  # External domain from secrets module for easier reference
  inherit (config.secrets) externalDomain;

  # Storage path for data access
  volumePath = "/Volumes/Storage";

  # Create a Caddy package with the required DNS plugin
  # Use the caddy-with-plugins overlay to get the withPlugins functionality
  caddyWithPlugins = pkgs.caddy-with-plugins.withPlugins {
    # https://github.com/caddy-dns/cloudflare/issues/97#issuecomment-2784508762
    plugins = [ "github.com/caddy-dns/cloudflare@v0.0.0-20250214163716-188b4850c0f2" ];
    hash = "sha256-dYZvFCSuDsOAYg8GgkdpulIzFud9EmP9mS81c87sOoY=";
  };

  # Path to the Caddyfile templates - main template plus mini-specific additions
  caddyfilePath = ../../../../templates/Caddyfile;
  caddyfileMiniPath = ../../../../templates/Caddyfile.mini;

  # Process the Caddyfile template with the local variables
  Caddyfile =
    pkgs.runCommand "caddyfile"
      {
        inherit bindAddress externalDomain;
        inherit (config.secrets) letsEncryptEmail;
        inherit (config.secrets) cloudflareApiToken;
        inherit (config.flags) beeIp;
        inherit (config.flags) miniIp;
        inherit (config.flags) a3wIp;
        logPathPrefix = "/tmp/log";

        # Element Web path
        elementWebPath = pkgs.mkElementWeb config.secrets.externalDomain;

        # Netdata credentials
        netdataBeeUsername = config.secrets.netdata.bee.username;
        netdataBeePassword = config.secrets.netdata.bee.password;
        netdataMiniUsername = config.secrets.netdata.mini.username;
        netdataMiniPassword = config.secrets.netdata.mini.password;

        # Zigbee credentials
        zigbeeUsername = config.secrets.zigbee.username;
        zigbeePassword = config.secrets.zigbee.password;
      }
      ''
        # Process main Caddyfile template
        substituteAll ${caddyfilePath} $out

        # Process mini-specific template and append
        echo "" >> $out
        substituteAll ${caddyfileMiniPath} /tmp/caddyfile-mini
        cat /tmp/caddyfile-mini >> $out
      '';
in
{
  # Configure launchd service for Caddy web server
  launchd.daemons.caddy = {
    serviceConfig = {
      Label = "org.nixos.caddy";
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/tmp/log/launchd/caddy.out.log";
      StandardErrorPath = "/tmp/log/launchd/caddy.error.log";
      ThrottleInterval = 10; # Restart on failure after 10 seconds
    };

    # Using command instead of ProgramArguments to utilize wait4path
    command =
      let
        # Create the Caddy starter script that waits for the volume
        caddyScript = pkgs.writeShellScriptBin "caddy-starter" ''
          # Wait for the Storage volume to be mounted using the built-in wait4path utility
          echo "Waiting for ${volumePath} to be available..."
          /bin/wait4path "${volumePath}"

          echo "${volumePath} is now available!"

          # Wait for network connectivity before starting Caddy
          echo "Waiting for network connectivity..."

          # Function to check if we have a valid IP address
          check_network() {
            # Check if we have a valid IP on en0 (typical main interface on Mac)
            # that matches our expected IP
            ip=$(ipconfig getifaddr en0)
            [ "$ip" = "${bindAddress}" ]
          }

          # Wait for network connectivity with a timeout
          TIMEOUT=60
          COUNTER=0
          while ! check_network; do
            if [ $COUNTER -ge $TIMEOUT ]; then
              echo "Network connectivity timeout after $TIMEOUT seconds!"
              echo "Starting Caddy anyway, but it may fail to bind to IP addresses..."
              break
            fi
            echo "Waiting for network connectivity... ($COUNTER/$TIMEOUT)"
            sleep 1
            COUNTER=$((COUNTER+1))
          done

          if [ $COUNTER -lt $TIMEOUT ]; then
            echo "Network connectivity established!"
          fi

          echo "Starting Caddy server..."

          # Launch caddy with our Caddyfile - specifying the caddyfile adapter
          exec ${caddyWithPlugins}/bin/caddy run --config ${Caddyfile} --adapter=caddyfile
        '';
      in
      "${caddyScript}/bin/caddy-starter";
  };
}
