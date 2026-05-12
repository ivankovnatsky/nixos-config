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
        "openclaw" = {
          binary = "openclaw";
          version = "latest";
          # Upstream postinstall silently fails during npm install -g
          # https://github.com/openclaw/openclaw/issues/59286
          postInstall = "node scripts/postinstall-bundled-plugins.mjs";
        };
        # Discord channel ships as a separate npm package since 2026.1.29;
        # openclaw npm bundle no longer includes it. Required for
        # channels.discord. Registration with openclaw happens via the
        # openclaw-gateway prestart script.
        "@openclaw/discord" = {
          version = "latest";
        };
      };

      uv.packages = {
        "gallery-dl" = {
          binary = "gallery-dl";
        };
        "yt-dlp" = {
          binary = "yt-dlp";
        };
        # Pip name `openai-whisper`, ships a `whisper` console script.
        # Required by openclaw's tools.media.audio configuration.
        "openai-whisper" = {
          binary = "whisper";
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
