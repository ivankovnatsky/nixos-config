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
            }
          }
        '';
      };
    };
  };
}