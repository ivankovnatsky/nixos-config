{ ... }:

let
  openClawVersion = "2026.5.26";
in
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
        "openclaw" = {
          binary = "openclaw";
          version = openClawVersion;
          # Upstream postinstall silently fails during npm install -g
          # https://github.com/openclaw/openclaw/issues/59286
          postInstall = "node scripts/postinstall-bundled-plugins.mjs";
        };
        # Discord channel ships as a separate npm package since 2026.1.29;
        # openclaw npm bundle no longer includes it. Required for
        # channels.discord. Registration with openclaw happens via the
        # openclaw-gateway prestart script.
        "@openclaw/discord" = {
          version = openClawVersion;
        };
        "@openclaw/codex" = {
          version = openClawVersion;
        };
        # Same shape as @openclaw/discord — separate npm package needed for
        # channels.whatsapp; openclaw-gateway prestart registers it.
        "@openclaw/whatsapp" = {
          version = openClawVersion;
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
