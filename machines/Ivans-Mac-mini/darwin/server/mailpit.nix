{
  config,
  pkgs,
  ...
}:

let
  certDir = "/var/lib/caddy/certificates/acme-v02.api.letsencrypt.org-directory";
in
{
  local.launchd.services.mailpit = {
    enable = true;
    type = "daemon";
    waitForSecrets = true;
    preStart = ''
      DOMAIN=$(cat ${config.sops.secrets.external-domain.path})
      CERT_PREFIX="$DOMAIN"
      WILDCARD_DIR="${certDir}/wildcard_.$DOMAIN"

      # Create symlinks with stable names for mailpit to use
      /bin/mkdir -p /tmp/mailpit-certs
      /bin/ln -sf "$WILDCARD_DIR/wildcard_.$DOMAIN.crt" /tmp/mailpit-certs/cert.crt
      /bin/ln -sf "$WILDCARD_DIR/wildcard_.$DOMAIN.key" /tmp/mailpit-certs/cert.key
    '';
    command = ''
      ${pkgs.mailpit}/bin/mailpit \
        --listen ${config.flags.machineBindAddress}:8025 \
        --smtp ${config.flags.machineBindAddress}:25 \
        --smtp-tls-cert /tmp/mailpit-certs/cert.crt \
        --smtp-tls-key /tmp/mailpit-certs/cert.key
    '';
  };
}
