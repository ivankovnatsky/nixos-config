{
  config,
  osConfig,
  pkgs,
  ...
}:

let
  inherit (osConfig.networking) hostName;
  homePath = config.home.homeDirectory;

  sourcesPath =
    if hostName == "Ivans-Mac-mini" then
      "${config.flags.externalStoragePath}/Sources"
    else
      "${homePath}/Sources";

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
              "command": "${pkgs.claude-statusline}/bin/claude-statusline"
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
