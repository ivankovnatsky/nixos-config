{
  config,
  lib,
  pkgs,
  ...
}:
let
  stateDir = "/Volumes/Storage/Data/.openclaw";
  patchedConfig = "${stateDir}/openclaw-runtime.json";

  # Wrapper that reads sops secrets, patches config, and execs the gateway
  gatewayWithSecrets = pkgs.writeShellScript "openclaw-gateway-secrets" ''
    export DISCORD_BOT_TOKEN=$(cat ${config.sops.secrets.openclaw-discord-bot-token.path})
    export ANTHROPIC_OAUTH_TOKEN=$(cat ${config.sops.secrets.openclaw-claude-oauth-token.path})
    export OPENCLAW_GATEWAY_TOKEN=$(cat ${config.sops.secrets.openclaw-gateway-token.path})

    # Copy nix-managed config to a mutable runtime copy and patch with secrets
    DOMAIN=$(cat ${config.sops.secrets.external-domain.path})
    if [ -L "$OPENCLAW_CONFIG_PATH" ]; then
      SRC="$(readlink "$OPENCLAW_CONFIG_PATH")"
    else
      SRC="$OPENCLAW_CONFIG_PATH"
    fi
    SERVER_ID=$(cat ${config.sops.secrets.openclaw-discord-server-id.path})
    USER_ID=$(cat ${config.sops.secrets.openclaw-discord-user-id.path})
    ${pkgs.jq}/bin/jq \
      --arg origin "https://openclaw.$DOMAIN" \
      --arg serverId "$SERVER_ID" \
      --arg userId "$USER_ID" \
      '.gateway.controlUi.allowedOrigins = [$origin, "http://127.0.0.1:18789"]
       | .channels.discord.allowFrom = [$userId]
       | .channels.discord.guilds[$serverId] = {}
       ' "$SRC" > "${patchedConfig}.tmp"
    mv "${patchedConfig}.tmp" "${patchedConfig}"
    export OPENCLAW_CONFIG_PATH="${patchedConfig}"

    exec "$@"
  '';
in
{
  programs.openclaw = {
    enable = true;
    package = pkgs.openclaw-gateway;
    installApp = false;
    toolNames = [ ];

    bundledPlugins.summarize.enable = true;

    instances.default = {
      enable = true;
      launchd.enable = true;
      inherit stateDir;

      config = {
        gateway = {
          mode = "local";
          auth.mode = "token";
          # FIXME: Reverse proxy pairing workaround. Remove when upstream fixes land.
          # https://github.com/openclaw/openclaw/issues/1679
          # https://github.com/openclaw/openclaw/issues/49293
          trustedProxies = [
            "127.0.0.1"
            "::1"
          ];
          controlUi.allowInsecureAuth = true;
        };

        channels.discord = {
          enabled = true;
        };
      };
    };
  };

  # Override the launchd agent to wrap the gateway with secret injection
  launchd.agents."com.steipete.openclaw.gateway".config.ProgramArguments = lib.mkForce [
    "${gatewayWithSecrets}"
    "${pkgs.openclaw-gateway}/bin/openclaw"
    "gateway"
    "--port"
    "18789"
  ];

  # Symlink CLI config to the runtime config so `openclaw` commands work
  home.file.".openclaw/openclaw.json".source = config.lib.file.mkOutOfStoreSymlink "${patchedConfig}";

  home.activation.openclawDashboardUrl = lib.hm.dag.entryAfter [ "openclawDirs" ] ''
    MARKER="${stateDir}/.dashboard-url-shown"
    if [ ! -f "$MARKER" ]; then
      TOKEN=$(cat ${config.sops.secrets.openclaw-gateway-token.path} 2>/dev/null || echo "")
      if [ -n "$TOKEN" ]; then
        DOMAIN=$(cat ${config.sops.secrets.external-domain.path} 2>/dev/null || echo "")
        if [ -n "$DOMAIN" ]; then
          /usr/bin/sudo -u ivan /usr/bin/open "https://openclaw.$DOMAIN/#token=$TOKEN"
          touch "$MARKER"
        fi
      fi
    fi
  '';

  sops.secrets.openclaw-discord-bot-token = {
    key = "discord/LizardBotToken";
  };

  sops.secrets.openclaw-claude-oauth-token = {
    key = "anthropic/oauthTokenOpenClaw";
  };

  sops.secrets.openclaw-gateway-token = {
    key = "openClaw/gatewayToken";
  };

  sops.secrets.openclaw-discord-server-id = {
    key = "discord/serverId";
  };

  sops.secrets.openclaw-discord-user-id = {
    key = "discord/userId";
  };

  sops.secrets.openclaw-discord-channel-id = {
    key = "discord/openClawChannelId";
  };
}
