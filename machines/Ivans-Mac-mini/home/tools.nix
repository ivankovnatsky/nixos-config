{ config, ... }:
{
  local.tools = {
    enable = true;
    toolsPrefix = config.flags.externalStoragePath;

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
      };

      # Python packages via uv tool install
      uv.packages = {
        "osxphotos" = {
          binary = "osxphotos";
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
