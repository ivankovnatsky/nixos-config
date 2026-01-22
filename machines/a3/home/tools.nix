{ config, ... }:
{
  local.tools = {
    enable = true;

    bun.packages = {
      "ccstatusline" = "ccstatusline";
      "@openai/codex" = "codex";
      "@google/gemini-cli" = "gemini";
    };

    curlShell = {
      "https://claude.ai/install.sh" = "bash";
    };

    mcp.servers = { };
  };
}
