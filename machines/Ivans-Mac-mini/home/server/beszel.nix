{
  config,
  pkgs,
  osConfig,
  ...
}:

let
  dataDir = "${config.flags.externalStoragePath}/.beszel-hub";
in
{
  # Beszel Hub service - user-agent to access /Volumes/Storage after login
  # See: claude/issues/LAUNCHD-BOOT-FAILURE.md
  # Manual restart: launchctl kickstart -k gui/$(id -u)/com.ivankovnatsky.beszel-hub
  # FIXME: config.yml is declarative - systems not defined will be deleted on restart
  local.launchd.services.beszel-hub = {
    enable = true;
    waitForPath = config.flags.externalStoragePath;
    waitForSecrets = true;
    inherit dataDir;
    command =
      let
        startScript = pkgs.writeShellScript "beszel-hub-start" ''
          set -e

          BESZEL_TOKEN="$(cat ${config.sops.secrets.beszel-token.path})"
          BESZEL_EMAIL="$(cat ${config.sops.secrets.beszel-email.path})"

          cat > ${dataDir}/config.yml << EOF
          systems:
            - name: ${osConfig.networking.hostName}
              host: ${config.flags.machineLocalAddress}
              port: 45876
              token: $BESZEL_TOKEN
              users:
                - $BESZEL_EMAIL
          EOF

          exec ${pkgs.nixpkgs-darwin-master-beszel.beszel}/bin/beszel-hub serve \
            --http ${config.flags.machineBindAddress}:8091 \
            --dir ${dataDir}
        '';
      in
      "${startScript}";
  };

  # Sops secrets for beszel-mgmt
  sops.secrets.beszel-email = {
    key = "beszel/email";
  };

  sops.secrets.beszel-password = {
    key = "beszel/password";
  };

  sops.secrets.beszel-token = {
    key = "beszel/token";
  };

  sops.secrets.discord-webhook-beszel = {
    key = "discord/webhookChannelMonitoringBeszel";
  };

  # Beszel management (declarative system sync)
  local.services.beszel-mgmt = {
    enable = true;
    externalDomainFile = config.sops.secrets.external-domain.path;
    emailFile = config.sops.secrets.beszel-email.path;
    passwordFile = config.sops.secrets.beszel-password.path;
    discordWebhookFile = config.sops.secrets.discord-webhook-beszel.path;
    systems = [
      {
        name = osConfig.networking.hostName;
        host = config.flags.machineLocalAddress;
        port = "45876";
      }
    ];
  };
}
