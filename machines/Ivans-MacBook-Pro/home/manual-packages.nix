{ config, ... }:
{
  local.manualPackages = {
    enable = true;

    # Declarative equivalents of the previous imperative installs
    npm.packages = {
      "@anthropic-ai/claude-code" = "claude";
      "@google/gemini-cli" = "gemini";
      "@openai/codex" = "codex";
    };

    # .npmrc is already provided via `home/npm.nix` for this machine
    # npm.configFile = "";

    # No MCP servers for this host currently; add here if needed later
    mcp.servers = { };
  };
}
