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
        "@bitwarden/cli" = {
          binary = "bw";
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
