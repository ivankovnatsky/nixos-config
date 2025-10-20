{ config, ... }:
{
  local.manualPackages = {
    enable = true;

    npm.packages = {
      "@anthropic-ai/claude-code" = "claude";
      "@openai/codex" = "codex";
      "@google/gemini-cli" = "gemini";
    };

    mcp.servers = { };
  };
}
