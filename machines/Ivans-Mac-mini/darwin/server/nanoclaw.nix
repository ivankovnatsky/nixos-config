{
  config,
  pkgs,
  username,
  ...
}:

let
  nanoclawDataPath = "${config.flags.externalStoragePath}/.nanoclaw";

  buildAgentImage = pkgs.writeShellScript "nanoclaw-build-agent-image" ''
    IMAGE="nanoclaw-agent:latest"
    CONTEXT="${pkgs.nanoclaw}/lib/nanoclaw/container"

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
    environment = {
      HOME = config.users.users.${username}.home;
      PATH = "${pkgs.nanoclaw}/bin:${pkgs.nixpkgs-darwin-master-container.container}/bin:/usr/local/bin:/usr/bin:/bin";
      NODE_ENV = "production";
      NANOCLAW_HOME = nanoclawDataPath;
      CREDENTIAL_PROXY_PORT = "3002";
    };
    command = "${pkgs.nanoclaw}/bin/nanoclaw";
  };
}
