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
    hash = "sha256-q0Y5l2Dan7lqNDLB/G7IYsBa1a9Vc/bCLyymOCTH/Jg=";
  };

  # Path to the Caddyfile template
  caddyfilePath = ../../../../templates/Caddyfile;

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
        elementWebPath = pkgs.mkElementWeb config.secrets.externalDomain "matrix";

        # Netdata credentials
        netdataBeeUsername = config.secrets.netdata.bee.username;
        netdataBeePassword = config.secrets.netdata.bee.password;
        netdataMiniUsername = config.secrets.netdata.mini.username;
        netdataMiniPassword = config.secrets.netdata.mini.password;

        # Zigbee credentials
        zigbeeUsername = config.secrets.zigbee.username;
        zigbeePassword = config.secrets.zigbee.password;

        # Podsync credentials
        podsyncUsername = config.secrets.podsync.username;
        podsyncPassword = config.secrets.podsync.password;
      }
      ''
        # Process main Caddyfile template
        substituteAll ${caddyfilePath} $out
      '';
in
{
  # Configure launchd service for Caddy web server
  local.launchd.services.caddy = {
    enable = true;
    type = "daemon";
    waitForPath = volumePath;
    extraDirs = [ "/tmp/log/caddy" ];
    command = ''
      ${caddyWithPlugins}/bin/caddy run --config ${Caddyfile} --adapter=caddyfile
    '';
  };
}
