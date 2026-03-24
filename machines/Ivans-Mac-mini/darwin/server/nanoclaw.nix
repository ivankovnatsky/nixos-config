{
  config,
  pkgs,
  username,
  ...
}:

let
  containerBin = "/opt/homebrew/bin/container";
  nanoclawDataPath = "${config.flags.externalStoragePath}/.nanoclaw";
  discordChannelIdFile = config.sops.secrets.nanoclaw-discord-channel-id.path;
  # Forked to ivankovnatsky/nanoclaw-discord with Apple Container patches.
  # Local clone at .nanoclaw has origin pointing to the fork.
  nanoclawRepo = "https://github.com/qwibitai/nanoclaw-discord.git";

  nodejs = pkgs.nodejs_22;

  nanoclawWrapper = pkgs.writeShellScript "nanoclaw-wrapper" ''
    export DISCORD_BOT_TOKEN=$(cat ${config.sops.secrets.discord-bot-token.path})
    export CLAUDE_CODE_OAUTH_TOKEN=$(cat ${config.sops.secrets.claude-oauth-token.path})
    cd ${nanoclawDataPath}
    exec ${nodejs}/bin/node dist/index.js
  '';

  nanoclawSetup = pkgs.writeShellScript "nanoclaw-setup" ''
    set -e
    export PATH="${nodejs}/bin:${pkgs.git}/bin:/usr/bin:/bin"
    export HOME="${config.users.users.${username}.home}"

    # Clone if needed
    if [ ! -d "${nanoclawDataPath}/.git" ]; then
      echo "Cloning nanoclaw-discord..."
      ${pkgs.git}/bin/git clone ${nanoclawRepo} ${nanoclawDataPath}
    fi

    cd ${nanoclawDataPath}

    # Bootstrap (follows setup.sh flow)
    # Unset NODE_ENV so npm ci installs devDependencies (typescript, tsx)
    if [ ! -d "node_modules" ] || [ "package-lock.json" -nt "node_modules/.package-lock.json" ]; then
      echo "Installing dependencies..."
      NODE_ENV= ${nodejs}/bin/npm ci
    fi

    # Verify native modules
    ${nodejs}/bin/node -e "require('better-sqlite3')"

    # Build
    if [ ! -d "dist" ]; then
      echo "Building..."
      ${nodejs}/bin/npm run build
    fi

    # Register Discord channel if not already registered
    DISCORD_CHANNEL_ID=$(cat ${discordChannelIdFile})
    if ! ${pkgs.sqlite}/bin/sqlite3 store/messages.db \
      "SELECT jid FROM registered_groups WHERE jid = 'dc:$DISCORD_CHANNEL_ID';" 2>/dev/null | /usr/bin/grep -q .; then
      echo "Registering Discord channel..."
      ${nodejs}/bin/npx tsx setup/index.ts --step register \
        -- \
        --jid "dc:$DISCORD_CHANNEL_ID" \
        --name "nanoclaw" \
        --folder "discord_main" \
        --trigger "@Beaver" \
        --channel discord \
        --no-trigger-required \
        --is-main
    fi

    # Write .env for credential proxy (reads from file, not environment)
    DISCORD_TOKEN=$(cat ${config.sops.secrets.discord-bot-token.path})
    OAUTH_TOKEN=$(cat ${config.sops.secrets.claude-oauth-token.path})
    printf "DISCORD_BOT_TOKEN=%s\nCLAUDE_CODE_OAUTH_TOKEN=%s\n" "$DISCORD_TOKEN" "$OAUTH_TOKEN" > .env

    echo "Setup complete"
  '';

  buildAgentImage = pkgs.writeShellScript "nanoclaw-build-agent-image" ''
    IMAGE="nanoclaw-agent:latest"
    CONTEXT="${nanoclawDataPath}/container"
    MARKER="${nanoclawDataPath}/.agent-image-hash"

    if [ ! -d "$CONTEXT" ]; then
      echo "NanoClaw not set up yet, skipping image build"
      exit 0
    fi

    # Rebuild if source changed (hash of agent-runner source)
    CURRENT_HASH=$(find "$CONTEXT" -type f | sort | xargs cat | /usr/bin/shasum | /usr/bin/cut -d' ' -f1)
    if [ -f "$MARKER" ] && [ "$(cat "$MARKER")" = "$CURRENT_HASH" ]; then
      echo "Image $IMAGE is up to date, skipping build"
      exit 0
    fi

    echo "Building $IMAGE from $CONTEXT..."
    ${containerBin} build -t "$IMAGE" "$CONTEXT"
    echo "$CURRENT_HASH" > "$MARKER"
    echo "Build complete: $IMAGE"
  '';
in
{
  local.launchd.services.nanoclaw-build-agent-image = {
    enable = true;
    type = "user-agent";
    keepAlive = false;
    command = "${buildAgentImage}";
  };

  local.launchd.services.nanoclaw = {
    enable = true;
    logTimestamp = false;
    type = "user-agent";
    waitForPath = config.flags.externalStoragePath;
    dataDir = nanoclawDataPath;
    preStart = "${nanoclawSetup}";
    environment = {
      HOME = config.users.users.${username}.home;
      PATH = "${nodejs}/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin";
      NODE_ENV = "production";
      CREDENTIAL_PROXY_PORT = "3002";
      ASSISTANT_NAME = "Beaver";
      CREDENTIAL_PROXY_HOST = "0.0.0.0";
      IDLE_TIMEOUT = "120000";
      CONTAINER_TIMEOUT = "300000";
    };
    command = "${nanoclawWrapper}";
  };

  sops.secrets.discord-bot-token = {
    key = "discord/AndyBotToken";
    owner = username;
  };

  sops.secrets.claude-oauth-token = {
    key = "anthropic/oauthToken";
    owner = username;
  };

  sops.secrets.nanoclaw-discord-channel-id = {
    key = "discord/nanoClawChannelId";
    owner = username;
  };
}
