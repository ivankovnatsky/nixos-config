{
  config,
  pkgs,
  username,
  ...
}:

let
  nanoclawDataPath = "${config.flags.externalStoragePath}/.nanoclaw";
  discordChannelId = "REPLACED_BY_SOPS";
  nanoclawRepo = "https://github.com/qwibitai/nanoclaw-discord.git";
  nanoclawRev = "ba9353c5ee7deb6011f308f45417f6a38917dd0e";

  nodejs = pkgs.nodejs_22;

  nanoclawWrapper = pkgs.writeShellScript "nanoclaw-wrapper" ''
    export DISCORD_BOT_TOKEN=$(cat ${config.sops.secrets.discord-bot-token.path})
    export ANTHROPIC_API_KEY=$(cat ${config.sops.secrets.anthropic-api-key.path})
    cd ${nanoclawDataPath}
    exec ${nodejs}/bin/node dist/index.js
  '';

  nanoclawSetup = pkgs.writeShellScript "nanoclaw-setup" ''
    set -e
    export PATH="${nodejs}/bin:${pkgs.git}/bin:${pkgs.python3}/bin:/usr/bin:/bin"
    export HOME="${config.users.users.${username}.home}"

    # Clone if needed
    if [ ! -d "${nanoclawDataPath}/.git" ]; then
      echo "Cloning nanoclaw-discord..."
      ${pkgs.git}/bin/git clone ${nanoclawRepo} ${nanoclawDataPath}
    fi

    cd ${nanoclawDataPath}

    # Update to pinned revision
    CURRENT_REV=$(${pkgs.git}/bin/git rev-parse HEAD)
    if [ "$CURRENT_REV" != "${nanoclawRev}" ]; then
      echo "Updating to ${nanoclawRev}..."
      ${pkgs.git}/bin/git fetch origin
      ${pkgs.git}/bin/git checkout ${nanoclawRev}
    fi

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

    # Apply Apple Container patches to compiled output
    if /usr/bin/grep -q 'Run: docker info' dist/container-runtime.js 2>/dev/null; then
      echo "Applying Apple Container patches..."
      /usr/bin/sed -i "" \
        -e "s|CONTAINER_RUNTIME_BIN = 'docker'|CONTAINER_RUNTIME_BIN = 'container'|g" \
        -e "s|CONTAINER_HOST_GATEWAY = 'host.docker.internal'|CONTAINER_HOST_GATEWAY = '192.168.64.1'|g" \
        -e 's|CONTAINER_RUNTIME_BIN} info|CONTAINER_RUNTIME_BIN} system status|g' \
        -e "s|ps --filter name=nanoclaw- --format '{{.Names}}'|ls --format json|g" \
        -e "s|const orphans = output.trim().split('\\\\n').filter(Boolean);|const containers = output.trim() ? JSON.parse(output) : []; const orphans = containers.filter((c) => c.name?.startsWith('nanoclaw-')).map((c) => c.name);|g" \
        -e 's|Run: docker info|Run: container system status|g' \
        dist/container-runtime.js
    fi

    # Register Discord channel if not already registered
    if ! ${pkgs.sqlite}/bin/sqlite3 store/messages.db \
      "SELECT jid FROM registered_groups WHERE jid = 'dc:${discordChannelId}';" 2>/dev/null | /usr/bin/grep -q .; then
      echo "Registering Discord channel..."
      ${nodejs}/bin/npx tsx setup/index.ts --step register \
        -- \
        --jid "dc:${discordChannelId}" \
        --name "nanoclaw" \
        --folder "discord_main" \
        --trigger "@Andy" \
        --channel discord \
        --no-trigger-required \
        --is-main
    fi

    echo "Setup complete"
  '';

  buildAgentImage = pkgs.writeShellScript "nanoclaw-build-agent-image" ''
    IMAGE="nanoclaw-agent:latest"
    CONTEXT="${nanoclawDataPath}/container"

    if [ ! -d "$CONTEXT" ]; then
      echo "NanoClaw not set up yet, skipping image build"
      exit 0
    fi

    # Check if image already exists
    if ${pkgs.nixpkgs-darwin-master-container.container}/bin/container image ls --format json 2>/dev/null | \
       /usr/bin/grep -q "nanoclaw-agent"; then
      echo "Image $IMAGE already exists, skipping build"
      exit 0
    fi

    echo "Building $IMAGE from $CONTEXT..."
    ${pkgs.nixpkgs-darwin-master-container.container}/bin/container build -t "$IMAGE" "$CONTEXT"
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
    type = "user-agent";
    waitForPath = config.flags.externalStoragePath;
    dataDir = nanoclawDataPath;
    preStart = "${nanoclawSetup}";
    environment = {
      HOME = config.users.users.${username}.home;
      PATH = "${nodejs}/bin:${pkgs.nixpkgs-darwin-master-container.container}/bin:/usr/local/bin:/usr/bin:/bin";
      NODE_ENV = "production";
      CREDENTIAL_PROXY_PORT = "3002";
    };
    command = "${nanoclawWrapper}";
  };

  sops.secrets.discord-bot-token = {
    key = "discord/AndyBotToken";
    owner = username;
  };
}
