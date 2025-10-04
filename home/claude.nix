{
  config,
  pkgs,
  osConfig,
  ...
}:

let
  inherit (osConfig.networking) hostName;
  homePath = config.home.homeDirectory;

  sourcesPath =
    if hostName == "Ivans-Mac-mini" then
      "/Volumes/Storage/Data/Sources"
    else if hostName == "bee" then
      "/storage/Data/Sources"
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
                "Read(${homePath}/.local/**)",
                "Read(${homePath}/Notes/**)"
              ],
              "deny": [
                "Bash(sudo:*)"
              ]
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
