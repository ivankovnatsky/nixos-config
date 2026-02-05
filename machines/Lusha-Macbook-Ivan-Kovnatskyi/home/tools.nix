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
      "ccstatusline" = "ccstatusline";
      "@openai/codex" = "codex";
      "@google/gemini-cli" = "gemini";
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
      vercel = {
        transport = "http";
        url = "https://mcp.vercel.com";
      };
    };
  };
}
