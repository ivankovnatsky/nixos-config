{
  pkgs,
  config,
  ...
}:

# Mac Mini Caddy configuration with waiting for volume mount
# LAN reverse proxy fronting services that mostly live on a3.

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
  bindAddress = config.flags.machineBindAddress;

  # Create a Caddy package with the required DNS plugin
  caddyWithPlugins = pkgs.caddy.withPlugins {
    plugins = [ "github.com/caddy-dns/cloudflare@v0.2.4" ];
    hash = "sha256-J0HWjCPoOoARAxDpG2bS9c0x5Wv4Q23qWZbTjd8nW84=";
  };

  # Path to the Caddyfile template
  caddyfilePath = ../../../../templates/Caddyfile;

  # Runtime Caddyfile path
  runtimeCaddyfile = "/tmp/caddy/Caddyfile";
in
{
  # Sops secrets for Caddy basic auth credentials
  sops.secrets.cloudflare-api-token = {
    key = "cloudflareApiToken";
  };

  sops.secrets.lets-encrypt-email = {
    key = "letsEncryptEmail";
  };

  # Configure launchd service for Caddy web server
  local.launchd.services.caddy = {
    enable = true;
    waitForSecrets = true;
    waitForPath = config.flags.externalStoragePath;
    extraDirs = [
      "/tmp/log/caddy"
      "/tmp/caddy"
    ];
    preStart = ''
      # Read secrets from files
      EXTERNAL_DOMAIN=$(cat ${config.sops.secrets.external-domain.path})
      LETS_ENCRYPT_EMAIL=$(cat ${config.sops.secrets.lets-encrypt-email.path})
      CLOUDFLARE_API_TOKEN=$(cat ${config.sops.secrets.cloudflare-api-token.path})

      # Substitute variables in Caddyfile template
      ${pkgs.gnused}/bin/sed \
        -e "s|@bindAddress@|${bindAddress}|g" \
        -e "s|@externalDomain@|$EXTERNAL_DOMAIN|g" \
        -e "s|@letsEncryptEmail@|$LETS_ENCRYPT_EMAIL|g" \
        -e "s|@cloudflareApiToken@|$CLOUDFLARE_API_TOKEN|g" \
        -e "s|@machineIp@|${config.flags.machineLocalAddress}|g" \
        -e "s|@a3Ip@|${config.flags.a3Ip}|g" \
        -e "s|@logPathPrefix@|/tmp/log|g" \
        ${caddyfilePath} > ${runtimeCaddyfile}

      # Set permissions
      chmod 600 ${runtimeCaddyfile}
    '';
    command = ''
      ${caddyWithPlugins}/bin/caddy run --config ${runtimeCaddyfile} --adapter=caddyfile
    '';
  };
}
