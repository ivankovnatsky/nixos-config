{ config, ... }:
{
  local.manualPackages = {
    enable = true;

    npm.packages = {
      "@anthropic-ai/claude-code" = "claude";
      "happy-coder" = "happy";
    };

    mcp.servers = { };
  };
}
