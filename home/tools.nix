{ ... }:
{
  local.tools = {
    enable = true;

    settings = {
      npm.packages = {
        "@earendil-works/pi-coding-agent" = {
          binary = "pi";
        };
        "@openai/codex" = {
          binary = "codex";
        };
        "@steipete/summarize" = {
          binary = "summarize";
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
        "gallery-dl" = {
          binary = "gallery-dl";
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
