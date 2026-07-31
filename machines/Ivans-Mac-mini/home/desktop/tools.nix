{ config, ... }:
{
  local.tools = {
    enable = true;
    toolsPrefix = config.flags.homeWorkPath;

    settings = {
      npm.packages = {
        "@earendil-works/pi-coding-agent" = { };
        "@openai/codex" = { };
        "@bitwarden/cli" = { };
        "@steipete/summarize" = { };
      };

      # Python packages via uv tool install
      uv.packages = {
        "osxphotos" = { };
        "yt-dlp" = { };
        "mlx-whisper" = { };
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
