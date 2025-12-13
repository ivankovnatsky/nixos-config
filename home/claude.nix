{
  config,
  ...
}:

let
  homePath = config.home.homeDirectory;

  sourcesPath = "${homePath}/Sources";

  claudeConfigPath = ".claude/settings.json";
in
{
  # https://docs.anthropic.com/en/docs/claude-code/settings
  home = {
    file = {
      "${claudeConfigPath}" = {
        text = ''
          {
            "permissions": {
              "defaultMode": "acceptEdits",
              "autoApproveWebFetch": true,
              "allow": [
                "Read(${sourcesPath}/**)",
                "Bash(git add:*)",
                "Bash(git log:*)",
                "WebFetch(domain:*)",
                "WebSearch",
                "Bash(nix-prefetch-url:*)",
                "Read(${homePath}/.config/**)",
                "Read(${homePath}/.local/**)"
              ],
              "deny": [
                "Bash(sudo:*)"
              ]
            },
            "statusLine": {
              "type": "command",
              "command": "printf '\\e[?1004l'; npx ccstatusline@latest",
              "padding": 0
            },
            "includeCoAuthoredBy": false,
            "env": {
              "CLAUDE_CODE_ENABLE_TELEMETRY": "1"
            }
          }
        '';
      };
    };
  };
}
