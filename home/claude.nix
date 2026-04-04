{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}:

let
  inherit (osConfig.networking) hostName;
  homePath = config.home.homeDirectory;
  isWork = config.flags.purpose == "work";

  sourcesPath =
    if hostName == "Ivans-Mac-mini" then
      "${config.flags.externalStoragePath}/Sources"
    else
      "${homePath}/Sources";

  claudeConfigPath = ".claude/settings.json";

  baseSettings = {
    model = "claude-opus-4-6[1m]";
    permissions = {
      defaultMode = "acceptEdits";
      autoApproveWebFetch = true;
      allow = [
        "Read(${sourcesPath}/**)"
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
      command = "${pkgs.claude-statusline}/bin/claude-statusline";
    };
    includeCoAuthoredBy = false;
    env = {
      CLAUDE_CODE_ENABLE_TELEMETRY = "1";
    };
  };
in
{
  # https://docs.anthropic.com/en/docs/claude-code/settings
  home = {
    file = {
      "${claudeConfigPath}" = {
        text = builtins.toJSON baseSettings;
      };
    };
  };

  sops.secrets.portkey-api-key = lib.mkIf isWork {
    key = "work/portkey/apiKey";
  };

  sops.templates."portkey.sh" = lib.mkIf isWork {
    content = builtins.concatStringsSep "\n" [
      "#!/bin/bash"
      "export ANTHROPIC_BASE_URL='https://api.portkey.ai'"
      "export ANTHROPIC_API_KEY=\"$(~/.claude/anthropic_key.sh)\""
      "export ANTHROPIC_CUSTOM_HEADERS=$'x-portkey-api-key: ${config.sops.placeholder.portkey-api-key}\\nx-portkey-provider: @anthropic'"
      "exec claude --allow-dangerously-skip-permissions \"$@\""
      ""
    ];
    mode = "0755";
  };

  sops.templates."anthropic_key.sh" = lib.mkIf isWork {
    content = builtins.concatStringsSep "\n" [
      "#!/bin/bash"
      "echo \"${config.sops.placeholder.anthropic-api-key}\""
      ""
    ];
    mode = "0755";
  };

  home.activation.linkClaudeSettings = lib.mkIf isWork (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD mkdir -p "${homePath}/.claude"
      $DRY_RUN_CMD ln -sf ${
        config.sops.templates."anthropic_key.sh".path
      } "${homePath}/.claude/anthropic_key.sh"
      $DRY_RUN_CMD ln -sf ${config.sops.templates."portkey.sh".path} "${homePath}/.claude/portkey.sh"
    ''
  );
}
