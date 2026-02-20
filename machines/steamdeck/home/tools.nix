{ ... }:
{
  local.tools = {
    enable = true;

    bun.packages = {
      "@openai/codex" = "codex";
      "@google/gemini-cli" = "gemini";
    };

    curlShell = {
      "https://claude.ai/install.sh" = "bash";
    };

    mcp.servers = { };
  };
}
