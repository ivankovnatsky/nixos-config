{ config, ... }:
{
  local.manualPackages = {
    enable = true;

    npm.packages = {
      "npm-groovy-lint" = "npm-groovy-lint";
      "@anthropic-ai/claude-code" = "claude";
      "ccstatusline" = "ccstatusline";
      "@openai/codex" = "codex";
      "@google/gemini-cli" = "gemini";
    };

    npm.configFile = ''
      prefix=~/.npm
    '';

    mcp.servers = {
      atlassian = {
        transport = "sse";
        url = "https://mcp.atlassian.com/v1/sse";
      };
      github = {
        transport = "http";
        url = "https://api.githubcopilot.com/mcp";
        headers = [ "Authorization: Bearer @GH_MCP_TOKEN@" ];
        secretPaths = {
          GH_MCP_TOKEN = config.sops.secrets.gh-mcp-token.path;
        };
      };
    };
  };
}
