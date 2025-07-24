{ config, pkgs, ... }:

let
  inherit (pkgs.stdenv.targetPlatform) isDarwin;

  claudeConfigPath = ".claude/settings.json";
in
{
  home = {
    packages = with pkgs; [ nixpkgs-master.claude-code ];
    file = {
      "${claudeConfigPath}" = {
        text = ''
          {
            "permissions": {
              "defaultMode": "acceptEdits"
            },
            "env": {
              "CLAUDE_CODE_ENABLE_TELEMETRY": "1"
            },
            "hooks": {
              "PreToolUse": [
                {
                  "matcher": "Bash",
                  "hooks": [
                    {
                      "type": "command",
                      "command": "if echo \"$CLAUDE_TOOL_INPUT\" | jq -r '.tool_input.command' | grep -q 'git commit'; then echo 'Git commit formatting: Use max 72 chars per line in commit body. Break long descriptions into multiple properly wrapped lines.'; fi"
                    }
                  ]
                }
              ]
            }
          }
        '';
      };
      ".claude/CLAUDE.md" = {
        text = ''
          # Personal Claude Code Memory

          ## Git Conventions
          - Use format: `file/path: action description` for commit subjects
          - Keep commit body lines under 72 characters
          - Break long descriptions into multiple properly wrapped lines
          - For long machine names, use short aliases like work and mini
          - Check git log for recent commits to align with existing conventions
        '';
      };
    };
  };
}