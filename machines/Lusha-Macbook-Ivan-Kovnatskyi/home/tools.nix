{ ... }:
{
  local.tools = {
    enable = true;

    settings = {
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

      uv.packages = {
        "gallery-dl" = {
          binary = "gallery-dl";
        };
        "yt-dlp" = {
          binary = "yt-dlp";
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
        "~/.agents/skills/terraform-skill" = "https://github.com/antonbabenko/terraform-skill";
      };

      mcp.servers = {
        context7 = {
          scope = "user";
          transport = "http";
          url = "https://mcp.context7.com/mcp";
        };
        playwright = {
          scope = "user";
          transport = "stdio";
          args = [
            "npx"
            "@playwright/mcp@latest"
          ];
        };
      };
    };
  };
}
