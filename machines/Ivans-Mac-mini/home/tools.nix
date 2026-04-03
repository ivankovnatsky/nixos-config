{ config, ... }:
{
  local.tools = {
    enable = true;
    toolsPrefix = config.flags.externalStoragePath;

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
      };
      # Undeclared runtime dep of openclaw's Discord plugin
      "@buape/carbon" = {
        binary = "carbon";
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
}
