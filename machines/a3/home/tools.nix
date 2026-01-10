{ config, ... }:
{
  local.tools = {
    enable = true;

    npm.packages = {
      "@anthropic-ai/claude-code" = "claude";
      "ccstatusline" = "ccstatusline";
      "@openai/codex" = "codex";
      "@google/gemini-cli" = "gemini";
    };

    mcp.servers = { };
  };
}
