{ pkgs
, config
, ...
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

  # Runtime Caddyfile path
  runtimeCaddyfile = "/tmp/caddy/Caddyfile";
in
{
  # Sops secrets for Caddy basic auth credentials
  sops.secrets.zigbee-username = {
    key = "zigbee/username";
  };

  sops.secrets.zigbee-password = {
    key = "zigbee/password";
  };

  sops.secrets.podsync-username = {
    key = "podsync/username";
  };

  sops.secrets.podsync-password = {
    key = "podsync/password";
  };

  sops.secrets.netdata-mini-username = {
    key = "netdata/mini/username";
  };

  sops.secrets.netdata-mini-password = {
    key = "netdata/mini/password";
  };

  sops.secrets.netdata-bee-username = {
    key = "netdata/bee/username";
  };

  sops.secrets.netdata-bee-password = {
    key = "netdata/bee/password";
  };

  sops.secrets.cloudflare-api-token = {
    key = "cloudflareApiToken";
  };

  sops.secrets.lets-encrypt-email = {
    key = "letsEncryptEmail";
  };

  sops.secrets.external-domain = {
    key = "externalDomain";
  };

  # Configure launchd service for Caddy web server
  local.launchd.services.caddy = {
    enable = true;
    type = "daemon";
    waitForPath = volumePath;
    extraDirs = [
      "/tmp/log/caddy"
      "/tmp/caddy"
    ];
    preStart = ''
      # Read secrets from files
      EXTERNAL_DOMAIN=$(cat ${config.sops.secrets.external-domain.path})
      LETS_ENCRYPT_EMAIL=$(cat ${config.sops.secrets.lets-encrypt-email.path})
      CLOUDFLARE_API_TOKEN=$(cat ${config.sops.secrets.cloudflare-api-token.path})
      ZIGBEE_USERNAME=$(cat ${config.sops.secrets.zigbee-username.path})
      ZIGBEE_PASSWORD=$(cat ${config.sops.secrets.zigbee-password.path})
      PODSYNC_USERNAME=$(cat ${config.sops.secrets.podsync-username.path})
      PODSYNC_PASSWORD=$(cat ${config.sops.secrets.podsync-password.path})
      NETDATA_BEE_USERNAME=$(cat ${config.sops.secrets.netdata-bee-username.path})
      NETDATA_BEE_PASSWORD=$(cat ${config.sops.secrets.netdata-bee-password.path})
      NETDATA_MINI_USERNAME=$(cat ${config.sops.secrets.netdata-mini-username.path})
      NETDATA_MINI_PASSWORD=$(cat ${config.sops.secrets.netdata-mini-password.path})

      # Element Web path using external domain from sops
      ELEMENT_WEB_PATH="${pkgs.mkElementWeb "$EXTERNAL_DOMAIN" "matrix"}"

      # Substitute variables in Caddyfile template
      ${pkgs.gnused}/bin/sed \
        -e "s|@bindAddress@|${bindAddress}|g" \
        -e "s|@externalDomain@|$EXTERNAL_DOMAIN|g" \
        -e "s|@letsEncryptEmail@|$LETS_ENCRYPT_EMAIL|g" \
        -e "s|@cloudflareApiToken@|$CLOUDFLARE_API_TOKEN|g" \
        -e "s|@beeIp@|${config.flags.beeIp}|g" \
        -e "s|@miniIp@|${config.flags.miniIp}|g" \
        -e "s|@a3wIp@|${config.flags.a3wIp}|g" \
        -e "s|@logPathPrefix@|/tmp/log|g" \
        -e "s|@elementWebPath@|$ELEMENT_WEB_PATH|g" \
        -e "s|@zigbeeUsername@|$ZIGBEE_USERNAME|g" \
        -e "s|@zigbeePassword@|$ZIGBEE_PASSWORD|g" \
        -e "s|@podsyncUsername@|$PODSYNC_USERNAME|g" \
        -e "s|@podsyncPassword@|$PODSYNC_PASSWORD|g" \
        -e "s|@netdataBeeUsername@|$NETDATA_BEE_USERNAME|g" \
        -e "s|@netdataBeePassword@|$NETDATA_BEE_PASSWORD|g" \
        -e "s|@netdataMiniUsername@|$NETDATA_MINI_USERNAME|g" \
        -e "s|@netdataMiniPassword@|$NETDATA_MINI_PASSWORD|g" \
        ${caddyfilePath} > ${runtimeCaddyfile}

      # Set permissions
      chmod 600 ${runtimeCaddyfile}
    '';
    command = ''
      ${caddyWithPlugins}/bin/caddy run --config ${runtimeCaddyfile} --adapter=caddyfile
    '';
  };
}
