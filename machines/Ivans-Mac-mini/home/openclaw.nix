{
  config,
  lib,
  pkgs,
  ...
}:
let
  stateDir = "${config.flags.externalStoragePath}/.openclaw";
  patchedConfig = "${stateDir}/openclaw-runtime.json";

  # Wrapper that patches config with SecretRefs and dynamic values, then execs the gateway.
  # Secrets are injected as file-based SecretRefs so they stay out of process.env
  # and are not visible to agents via `env`.
  gatewayWithSecrets = pkgs.writeShellScript "openclaw-gateway-secrets" ''
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
      --arg gatewayTokenPath "${config.sops.secrets.openclaw-gateway-token.path}" \
      --arg discordTokenPath "${config.sops.secrets.openclaw-discord-bot-token.path}" \
      --arg anthropicTokenPath "${config.sops.secrets.openclaw-claude-oauth-token.path}" \
      '
       .secrets.providers["sops-gateway-token"] = { source: "file", path: $gatewayTokenPath, mode: "singleValue" }
       | .secrets.providers["sops-discord-token"] = { source: "file", path: $discordTokenPath, mode: "singleValue" }
       | .secrets.providers["sops-anthropic-token"] = { source: "file", path: $anthropicTokenPath, mode: "singleValue" }
       | .gateway.auth.token = { source: "file", provider: "sops-gateway-token", id: "value" }
       | .channels.discord.token = { source: "file", provider: "sops-discord-token", id: "value" }
       | .models.providers.anthropic = {
           baseUrl: "https://api.anthropic.com",
           models: [],
           apiKey: { source: "file", provider: "sops-anthropic-token", id: "value" }
         }
       | .gateway.controlUi.allowedOrigins = [$origin, "http://127.0.0.1:18789"]
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
        agents.defaults = {
          model = {
            primary = "anthropic/claude-opus-4-6";
            fallbacks = [
              "openai-codex/gpt-5.4"
            ];
          };

          models = {
            "anthropic/claude-opus-4-6" = {
              alias = "opus";
            };

            "openai-codex/gpt-5.4" = {
              params.transport = "auto";
            };
          };
        };

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
