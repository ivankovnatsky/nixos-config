{
  config,
  pkgs,
  username,
  ...
}:

let
  dataDir = "${config.flags.miniStoragePath}/.beszel-hub";
in
{
  # Beszel Hub service - user-agent to access /Volumes/Storage after login
  # See: claude/issues/LAUNCHD-BOOT-FAILURE.md
  # Manual restart: launchctl kickstart -k gui/$(id -u)/com.ivankovnatsky.beszel-hub
  # FIXME: config.yml is declarative - systems not defined will be deleted on restart
  local.launchd.services.beszel-hub = {
    enable = true;
    type = "user-agent";
    waitForPath = config.flags.miniStoragePath;
    dataDir = dataDir;
    command =
      let
        startScript = pkgs.writeShellScript "beszel-hub-start" ''
          set -e

          BESZEL_TOKEN="$(cat ${config.sops.secrets.beszel-token.path})"
          BESZEL_EMAIL="$(cat ${config.sops.secrets.beszel-email.path})"

          cat > ${dataDir}/config.yml << EOF
          systems:
            - name: Ivans-Mac-mini
              host: ${config.flags.miniIp}
              port: 45876
              token: $BESZEL_TOKEN
              users:
                - $BESZEL_EMAIL
          EOF

          exec ${pkgs.nixpkgs-darwin-master-beszel.beszel}/bin/beszel-hub serve \
            --http ${config.flags.miniIp}:8091 \
            --dir ${dataDir}
        '';
      in
      "${startScript}";
  };

  # Beszel Agent (monitoring mini itself)
  sops.secrets.beszel-hub-public-key = {
    key = "beszel/hubPublicKey";
  };

  local.services.beszel-agent = {
    enable = true;
    package = pkgs.nixpkgs-darwin-master-beszel.beszel;
    port = 45876;
    listenAddress = config.flags.miniIp;
    hubPublicKeyFile = config.sops.secrets.beszel-hub-public-key.path;
    waitForSecrets = true;
  };

  # Sops secrets for beszel-mgmt
  sops.secrets.beszel-email = {
    key = "beszel/email";
    owner = username;
  };

  sops.secrets.beszel-password = {
    key = "beszel/password";
    owner = username;
  };

  sops.secrets.beszel-token = {
    key = "beszel/token";
    owner = username;
  };

  sops.secrets.discord-webhook = {
    key = "discordWebHook";
    owner = username;
  };

  # Beszel management (declarative system sync)
  local.services.beszel-mgmt = {
    enable = true;
    externalDomainFile = config.sops.secrets.external-domain.path;
    emailFile = config.sops.secrets.beszel-email.path;
    passwordFile = config.sops.secrets.beszel-password.path;
    discordWebhookFile = config.sops.secrets.discord-webhook.path;
    systems = [
      {
        name = "Ivans-Mac-mini";
        host = config.flags.miniIp;
        port = "45876";
      }
    ];
  };
}
