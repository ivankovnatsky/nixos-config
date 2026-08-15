{
  config,
  pkgs,
  ...
}:

let
  caddyWithPlugins = pkgs.caddy.withPlugins {
    plugins = [ "github.com/caddy-dns/cloudflare@v0.2.4" ];
    hash = "sha256-hEHgAG0F0ozHRAPuxEqLyTATBrE+pajeXDiSNwniorg=";
  };

  caddyfileTemplate = ../../../../templates/Caddyfile;
  runtimeCaddyfile = "/var/lib/caddy/Caddyfile";
in
{
  sops.secrets.cloudflare-api-token.key = "cloudflareApiToken";
  sops.secrets.lets-encrypt-email.key = "letsEncryptEmail";

  local.launchd.services.caddy = {
    enable = true;
    waitForSecrets = true;
    extraDirs = [
      "/tmp/log/caddy"
      "/var/lib/caddy"
    ];
    environment.HOME = "/var/lib/caddy";
    preStart = ''
      umask 077

      while [ ! -f "${config.sops.secrets.external-domain.path}" ] || \
            [ ! -f "${config.sops.secrets.lets-encrypt-email.path}" ] || \
            [ ! -f "${config.sops.secrets.cloudflare-api-token.path}" ]; do
        sleep 1
      done

      external_domain=$(cat ${config.sops.secrets.external-domain.path})
      lets_encrypt_email=$(cat ${config.sops.secrets.lets-encrypt-email.path})
      cloudflare_api_token=$(cat ${config.sops.secrets.cloudflare-api-token.path})

      ${pkgs.gnused}/bin/sed \
        -e "s|@bindAddress@|${config.inventory.machineBindAddress}|g" \
        -e "s|@externalDomain@|$external_domain|g" \
        -e "s|@letsEncryptEmail@|$lets_encrypt_email|g" \
        -e "s|@cloudflareApiToken@|$cloudflare_api_token|g" \
        -e "s|@machineIp@|${config.inventory.miniIp}|g" \
        -e "s|@a3Ip@|${config.inventory.a3Ip}|g" \
        -e "s|@logPathPrefix@|/tmp/log|g" \
        ${caddyfileTemplate} > ${runtimeCaddyfile}

      chmod 600 ${runtimeCaddyfile}
    '';
    command = "${caddyWithPlugins}/bin/caddy run --config ${runtimeCaddyfile} --adapter=caddyfile";
  };
}
