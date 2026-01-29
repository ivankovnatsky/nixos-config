{ ... }:
{
  local.tools = {
    enable = true;

    bun.packages = {
      "ccstatusline" = "ccstatusline";
      "@google/gemini-cli" = "gemini";
      "@openai/codex" = "codex";
    };

    # Python packages via uv tool install
    uv.packages = {
      "osxphotos" = "osxphotos";
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
