{ pkgs, ... }:

{
  system.activationScripts.postActivation.text = ''
    ${pkgs.settingsctl}/bin/settings accessibility set "bash,Hammerspoon,kitty,Mac Mouse Fix Helper,Terminal"
  '';
}
