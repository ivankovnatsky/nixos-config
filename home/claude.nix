{ config, pkgs, osConfig, ... }:

let
  inherit (pkgs.stdenv.targetPlatform) isDarwin;
  
  hostName = osConfig.networking.hostName;
  homePath = config.home.homeDirectory;
  
  sourcesPath = if hostName == "Ivans-Mac-mini" then
    "/Volumes/Storage/Data/Sources"
  else if hostName == "bee" then
    "/storage/Data/Sources"
  else
    "${homePath}/Sources";

  claudeConfigPath = ".claude/settings.json";
in
{
  home = {
    file = {
      "${claudeConfigPath}" = {
        text = ''
          {
            "permissions": {
              "defaultMode": "acceptEdits",
              "autoApproveWebFetch": true,
              "allow": [
                "Read(${sourcesPath}/**)"
              ],
              "deny": [
                "Bash(sudo:*)",
                "Bash(rm -rf:*)",
                "Bash(chmod:*)",
                "Bash(git reset:*)"
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
