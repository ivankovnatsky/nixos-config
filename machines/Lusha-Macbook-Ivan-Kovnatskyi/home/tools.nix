{ config, ... }:
{
  local.tools = {
    enable = true;

    npm = {
      configFile = ''
        prefix=~/.npm
      '';
      packages = { };
    };

    bun.packages = {
      "npm-groovy-lint" = "npm-groovy-lint";
      "ccstatusline" = "ccstatusline";
      "@openai/codex" = "codex";
      "@google/gemini-cli" = "gemini";
    };

    curlShell = {
      "https://claude.ai/install.sh" = "bash";
    };

    mcp.servers = {
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
