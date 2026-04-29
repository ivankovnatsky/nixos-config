{
  config,
  pkgs,
  ...
}:

let
  homePath = config.home.homeDirectory;

  # Structured Claude Code settings. The shape mirrors what a future
  # tools-config YAML entry would carry, so this can be lifted out of
  # Nix later with minimal churn.
  #
  # See: https://docs.anthropic.com/en/docs/claude-code/settings
  claudeSettings = {
    env = {
      CLAUDE_CODE_ENABLE_TELEMETRY = "1";
    };
    includeCoAuthoredBy = false;
    feedbackSurveyRate = 0;
    effortLevel = "high";
    skipDangerousModePermissionPrompt = true;
    skipAutoPermissionPrompt = true;
    permissions = {
      defaultMode = "auto";
      autoApproveWebFetch = true;
      allow = [
        "Read(${config.flags.externalStoragePath}/Sources/**)"
        "Bash(git add:*)"
        "Bash(git log:*)"
        "WebFetch(domain:*)"
        "WebSearch"
        "Bash(nix-prefetch-url:*)"
        "Read(${homePath}/.config/**)"
        "Read(${homePath}/.local/**)"
      ];
      deny = [
        "Bash(sudo:*)"
      ];
    };
    statusLine = {
      type = "command";
      command = "${homePath}/.local/bin/claude-statusline";
    };
  };

  claudeSettingsJson = pkgs.writeText "claude-settings.json" (
    builtins.toJSON claudeSettings
  );
in
{
  local.tools.settings.files = [
    {
      source = "${claudeSettingsJson}";
      target = "${homePath}/.claude/settings.json";
      mode = "0644";
    }
    {
      source = "${pkgs.claude-statusline}/bin/claude-statusline";
      target = "${homePath}/.local/bin/claude-statusline";
      mode = "0755";
    }
  ];
}
