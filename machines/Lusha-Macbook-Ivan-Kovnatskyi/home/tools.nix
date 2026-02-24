{ ... }:
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
      "@openai/codex" = "codex";
      "@google/gemini-cli" = "gemini";
      "mdts" = "mdts";
      "md-fileserver" = "mdstart";
    };

    curlShell = {
      "https://claude.ai/install.sh" = "bash";
    };

    gitRepos = {
      "~/.claude/skills/terraform-skill" = "https://github.com/antonbabenko/terraform-skill";
    };

    mcp.servers = {
      context7 = {
        transport = "http";
        url = "https://mcp.context7.com/mcp";
      };
    };
  };
}
