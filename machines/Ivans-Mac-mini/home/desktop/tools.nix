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
        "@openai/codex" = {
          binary = "codex";
        };
        "@bitwarden/cli" = {
          binary = "bw";
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

      go.packages = { };

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
