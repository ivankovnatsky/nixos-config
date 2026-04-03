{ ... }:
{
  local.tools = {
    enable = true;

    npm = {
      configFile = ''
        prefix=~/.npm
      '';
      packages = {
        "@google/gemini-cli" = {
          binary = "gemini";
        };
        "@openai/codex" = {
          binary = "codex";
        };
      };
    };

    bun.packages = {
      "npm-groovy-lint" = {
        binary = "npm-groovy-lint";
      };
      "mdts" = {
        binary = "mdts";
      };
      "md-fileserver" = {
        binary = "mdstart";
      };
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
      playwright = {
        transport = "stdio";
        args = [
          "npx"
          "@playwright/mcp@latest"
        ];
      };
    };
  };
}
