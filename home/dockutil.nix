{ pkgs, ... }:

{
  home.file.".dockutil/config".text = ''
    ${pkgs.dockutil}/bin/dockutil --remove all
    ${pkgs.dockutil}/bin/dockutil --add "/Applications/iTerm.app"
    ${pkgs.dockutil}/bin/dockutil --add "/Applications/Firefox.app"
    ${pkgs.dockutil}/bin/dockutil --add "/System/Applications/Utilities/Terminal.app"
    ${pkgs.dockutil}/bin/dockutil --add "/System/Cryptexes/App/System/Applications/Safari.app"
    ${pkgs.dockutil}/bin/dockutil --add "/System/Applications/Messages.app"
    ${pkgs.dockutil}/bin/dockutil --add "/System/Applications/Reminders.app"
    ${pkgs.dockutil}/bin/dockutil --add "/System/Applications/Notes.app"
    ${pkgs.dockutil}/bin/dockutil --add "/System/Applications/Utilities/Activity Monitor.app"
    ${pkgs.dockutil}/bin/dockutil --add "/System/Applications/System Settings.app"
  '';
}
