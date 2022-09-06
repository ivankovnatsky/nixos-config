{ config, pkgs, ... }:

{
  home.file.".dockutil/config".text = ''
    ${pkgs.dockutil}/bin/dockutil --remove all
    ${pkgs.dockutil}/bin/dockutil --add "/Applications/iTerm.app"
    ${pkgs.dockutil}/bin/dockutil --add "/Applications/Firefox.app"
  '';
}
