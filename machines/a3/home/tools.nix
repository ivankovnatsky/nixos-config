{ ... }:
{
  local.tools = {
    enable = true;

    settings = {
      npm.packages = {
        "@google/gemini-cli" = {
          binary = "gemini";
        };
        "@openai/codex" = {
          binary = "codex";
        };
      };

      uv.packages = {
        "gallery-dl" = {
          binary = "gallery-dl";
        };
        "yt-dlp" = {
          binary = "yt-dlp";
        };
      };

      curlShell = {
        "https://claude.ai/install.sh" = "bash";
      };

      mcp.servers = { };
    };
  };
}
