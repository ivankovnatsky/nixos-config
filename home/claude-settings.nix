{
  config,
  lib,
  pkgs,
  ...
}:

let
  homePath = config.home.homeDirectory;
  isWork = config.flags.purpose == "work";

  # Matchers anchor on a command-segment boundary (start of input or
  # `;` / `&&` / `||` / `|`) followed by optional whitespace. Hyphenated
  # wrappers (`git-commit-scope`, `gh-pr`) are not matched because the
  # regex requires whitespace between tokens — no allowlist needed.
  hookScript = pkgs.writeShellScript "claude-pretooluse-hook" ''
    CMD=$(${pkgs.jq}/bin/jq -r '.tool_input.command // empty')
    [ -z "$CMD" ] && exit 0

    # Block raw `git commit`
    if echo "$CMD" | grep -qE '(^|[;&|]+)[[:space:]]*git[[:space:]]+commit([[:space:]]|$)'; then
      echo "Use git-commit-scope or /commit skill instead of raw git commit" >&2
      exit 2
    fi

    # Block raw `gh pr create`
    if echo "$CMD" | grep -qE '(^|[;&|]+)[[:space:]]*gh[[:space:]]+pr[[:space:]]+create([[:space:]]|$)'; then
      echo "Use gh-pr create or /pr skill instead of raw gh pr create" >&2
      exit 2
    fi

    # Block raw jira CLI
    if echo "$CMD" | grep -qE '(^|[;&|]+)[[:space:]]*jira([[:space:]]|$)'; then
      echo "Use /jira skill instead of raw jira CLI" >&2
      exit 2
    fi

    exit 0
  '';

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
        "Read(${config.flags.homeWorkPath}/Sources/**)"
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
  }
  // lib.optionalAttrs isWork {
    hooks = {
      PreToolUse = [
        {
          matcher = "Bash";
          hooks = [
            {
              type = "command";
              command = "${homePath}/.local/bin/claude-pretooluse-hook";
            }
          ];
        }
      ];
    };
  };

  claudeSettingsJson = pkgs.writeText "claude-settings.json" (builtins.toJSON claudeSettings);
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
  ]
  ++ lib.optionals isWork [
    {
      source = "${hookScript}";
      target = "${homePath}/.local/bin/claude-pretooluse-hook";
      mode = "0755";
    }
  ];
}
