{ ... }:

{
  local.tools = {
    enable = true;

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

      uv.packages = {
        "yt-dlp" = {
          binary = "yt-dlp";
        };
      };

      go.packages = {
        rclone = {
          source = "github.com/rclone/rclone";
          binary = "rclone";
        };
      };

      curlShell = {
        "https://claude.ai/install.sh" = "bash";
      };

      mcp.servers = { };
    };
  };
}
