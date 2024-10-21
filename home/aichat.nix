{ config, pkgs, ... }:

let
  inherit (pkgs.stdenv.targetPlatform) isDarwin;

  aichatConfigPath = if isDarwin then "Library/Application Support/aichat/config.yaml" else ".config/aichat/config.yaml";
in
{
  home = {
    packages = with pkgs; [ nixpkgs-master.aichat ];
    file = {
      "${aichatConfigPath}" = {
        text = ''
          ${if config.flags.darkMode then "" else
          ''
          light_theme: true
          ''
          }
          save: true
          highlight: true
          keybindings: vi
          clients:
        '';
      };
    };
  };
}
