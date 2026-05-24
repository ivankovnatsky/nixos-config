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
  hookScript = pkgs.writeShellScript "claude-pretooluse-hook" (
    lib.removeSuffix "\n" ''
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

      # Block `git reset`
      if echo "$CMD" | grep -qE '(^|[;&|]+)[[:space:]]*git[[:space:]]+reset([[:space:]]|$)'; then
        echo "git reset is forbidden — use /commit skill, git-commit-scope <file-or-dir>, or plain git commit <file-or-dir> instead" >&2
        exit 2
      fi

      exit 0
    ''
  );

  # Static Claude Code settings live in ./claude-settings.json so they can
  # be diffed directly against the deployed ~/.claude/settings.json. The
  # `@HOME@` / `@HOME_WORK_PATH@` placeholders are the only machine-specific
  # bits; `hooks` is layered on below because it is work-machine only.
  #
  # Diff source against the live file:
  #   diff ~/.claude/settings.json home/claude-settings.json
  # (path lines differ by placeholder; `hooks` is absent from the source)
  #
  # See: https://docs.anthropic.com/en/docs/claude-code/settings
  baseSettings = builtins.fromJSON (
    builtins.replaceStrings [ "@HOME@" "@HOME_WORK_PATH@" ] [ homePath config.flags.homeWorkPath ] (
      builtins.readFile ./claude-settings.json
    )
  );

  claudeSettings =
    baseSettings
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

  # `pkgs.formats.json` pretty-prints via `jq`, so the deployed file
  # stays human-readable and the tools activation diff shows real
  # line-level changes instead of one squashed line.
  claudeSettingsJson = (pkgs.formats.json { }).generate "claude-settings.json" claudeSettings;
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
