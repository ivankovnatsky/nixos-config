{ config, ... }:
{
  local.manualPackages = {
    enable = true;

    npm.packages = {
      "npm-groovy-lint" = "npm-groovy-lint";
      "@anthropic-ai/claude-code" = "claude";
      "@openai/codex" = "codex";
      "@google/gemini-cli" = "gemini";
    };

    npm.configFile = ''
      prefix=~/.npm
    '';

    mcp.servers = {
      github = {
        transport = "http";
        url = "https://api.githubcopilot.com/mcp";
        headers = [ "Authorization: Bearer ${config.secrets.ghMcpToken}" ];
      };
    };
  };
}
