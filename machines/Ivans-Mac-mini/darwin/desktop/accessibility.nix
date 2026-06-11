{ pkgs, ... }:

{
  system.activationScripts.postActivation.text = ''
    ${pkgs.settingsctl}/bin/settings accessibility set "Hammerspoon,Mac Mouse Fix Helper,Terminal,kitty"
  '';
}
