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
      };

      uv.packages = {
        "yt-dlp" = {
          binary = "yt-dlp";
        };
      };

      go.packages = { };

      curlShell = {
        "https://claude.ai/install.sh" = "bash";
      };

      mcp.servers = { };
    };
  };
}
