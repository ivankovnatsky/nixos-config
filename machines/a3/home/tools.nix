{ ... }:
{
  local.tools = {
    enable = true;

    settings = {
      npm.packages = {
        "@google/gemini-cli" = {
          binary = "gemini";
        };
        "@openai/codex" = {
          binary = "codex";
        };
      };

      curlShell = {
        "https://claude.ai/install.sh" = "bash";
      };

      mcp.servers = { };
    };
  };
}
