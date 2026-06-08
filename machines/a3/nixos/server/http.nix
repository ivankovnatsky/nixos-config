{
  config,
  lib,
  pkgs,
  ...
}:

let
  caddyWithPlugins = pkgs.caddy.withPlugins {
    plugins = [ "github.com/caddy-dns/cloudflare@v0.2.4" ];
    hash = "sha256-8yZDrejNKsaUnUaTUFYbarWNmxafqp2z2rWo+XRsxV8=";
  };

  caddyfileTemplate = ../../../../templates/Caddyfile;
  runtimeCaddyfile = "/run/caddy/Caddyfile";
in
{
  sops.secrets.cloudflare-api-token = {
    key = "cloudflareApiToken";
    owner = "caddy";
  };

  sops.secrets.lets-encrypt-email = {
    key = "letsEncryptEmail";
    owner = "caddy";
  };

  services.caddy = {
    enable = true;
    package = caddyWithPlugins;
    configFile = runtimeCaddyfile;
  };

  systemd.services.caddy = {
    after = [
      "sops-nix.service"
      "network-online.target"
    ];
    wants = [
      "sops-nix.service"
      "network-online.target"
    ];
    serviceConfig.RuntimeDirectory = "caddy";
    preStart = lib.mkAfter ''
      umask 077

      external_domain=$(cat ${config.sops.secrets.external-domain.path})
      lets_encrypt_email=$(cat ${config.sops.secrets.lets-encrypt-email.path})
      cloudflare_api_token=$(cat ${config.sops.secrets.cloudflare-api-token.path})

      ${pkgs.gnused}/bin/sed \
        -e "s|@bindAddress@|0.0.0.0|g" \
        -e "s|@externalDomain@|$external_domain|g" \
        -e "s|@letsEncryptEmail@|$lets_encrypt_email|g" \
        -e "s|@cloudflareApiToken@|$cloudflare_api_token|g" \
        -e "s|@machineIp@|${config.inventory.miniIp}|g" \
        -e "s|@a3Ip@|${config.inventory.a3Ip}|g" \
        -e "s|@logPathPrefix@|/var/log|g" \
        ${caddyfileTemplate} > ${runtimeCaddyfile}
    '';
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
