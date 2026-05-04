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

  hookScript = pkgs.writeShellScript "claude-pretooluse-hook" ''
    CMD=$(jq -r '.tool_input.command // empty' 2>/dev/null)
    [ -z "$CMD" ] && exit 0

    # Block raw git commit (allow git-commit-scope)
    if ! echo "$CMD" | grep -q 'git-commit-scope'; then
      if echo "$CMD" | grep -qE '(^|[;&|] *)git commit($| )'; then
        echo "Use git-commit-scope or /commit skill instead of raw git commit" >&2
        exit 2
      fi
    fi

    # Block raw gh pr create (allow gh-pr)
    if ! echo "$CMD" | grep -q 'gh-pr'; then
      if echo "$CMD" | grep -qE '(^|[;&|] *)gh pr create($| )'; then
        echo "Use gh-pr create or /pr skill instead of raw gh pr create" >&2
        exit 2
      fi
    fi

    # Block raw jira CLI
    if echo "$CMD" | grep -qE '(^|[;&|] *)jira($| )'; then
      echo "Use /jira skill instead of raw jira CLI" >&2
      exit 2
    fi

    exit 0
  '';

  claudeConfigPath = ".claude/settings.json";

  baseSettings = {
    permissions = {
      defaultMode = "bypassPermissions";
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
    feedbackSurveyRate = 0;
    env = {
      CLAUDE_CODE_ENABLE_TELEMETRY = "1";
    };
  }
  // lib.optionalAttrs isWork {
    hooks = {
      PreToolUse = [
        {
          matcher = "Bash";
          hooks = [
            {
              type = "command";
              command = "${hookScript}";
            }
          ];
        }
      ];
    };
  };
in
{
  sops.secrets.portkey-api-key = lib.mkIf isWork {
    key = "work/portkey/apiKey";
  };

  sops.templates."portkey.sh" = lib.mkIf isWork {
    content = builtins.concatStringsSep "\n" [
      "#!/bin/bash"
      "export ANTHROPIC_BASE_URL='https://api.portkey.ai'"
      "export ANTHROPIC_API_KEY=\"$(~/.claude/anthropic_key.sh)\""
      "export ANTHROPIC_CUSTOM_HEADERS=$'x-portkey-api-key: ${config.sops.placeholder.portkey-api-key}\\nx-portkey-provider: @anthropic'"
      "exec claude \"$@\""
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
