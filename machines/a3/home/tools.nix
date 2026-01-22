{ config, ... }:
{
  local.tools = {
    enable = true;

    bun.packages = {
      "ccstatusline" = "ccstatusline";
      "@openai/codex" = "codex";
      "@google/gemini-cli" = "gemini";
    };

    mcp.servers = { };
  };
}
