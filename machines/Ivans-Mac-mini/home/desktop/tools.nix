{ config, ... }:
{
  local.tools = {
    enable = true;
    toolsPrefix = config.flags.homeWorkPath;

    settings = {
      npm.packages = {
        "@earendil-works/pi-coding-agent" = {
          binary = "pi";
        };
        "@google/gemini-cli" = {
          binary = "gemini";
        };
        "@openai/codex" = {
          binary = "codex";
        };
      };

      # Python packages via uv tool install
      uv.packages = {
        "osxphotos" = {
          binary = "osxphotos";
        };
        "yt-dlp" = {
          binary = "yt-dlp";
        };
      };

      # Go packages via `go install`. rclone from upstream because
      # nixpkgs.rclone has been failing the iCloud Drive auth flow
      # with HTTP 400 / "Invalid Session Token" and the latest
      # upstream release works around it. Note: `version: latest`
      # resolves to the highest tagged release at first install only
      # — subsequent activations no-op while the binary exists. To
      # refresh, delete `${toolsPrefix}/.go/bin/rclone` or pin a
      # `commit`.
      go.packages = {
        rclone = {
          source = "github.com/rclone/rclone";
          binary = "rclone";
        };
      };

      # .npmrc is already provided via `home/npm.nix` for this machine
      # npm.configFile = "";

      curlShell = {
        "https://claude.ai/install.sh" = "bash";
      };

      # No MCP servers for this host currently; add here if needed later
      mcp.servers = { };
    };
  };
}
