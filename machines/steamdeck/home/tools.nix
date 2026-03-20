{ ... }:
{
  local.tools = {
    enable = true;

    npm.packages = {
      "@google/gemini-cli" = "gemini";
      "@openai/codex" = "codex";
    };

    curlShell = {
      "https://claude.ai/install.sh" = "bash";
    };

    mcp.servers = { };
  };
}
