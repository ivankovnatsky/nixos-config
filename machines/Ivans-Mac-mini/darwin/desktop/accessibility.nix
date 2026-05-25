{ pkgs, ... }:

{
  system.activationScripts.postActivation.text = ''
    ${pkgs.settings}/bin/settings accessibility set "Hammerspoon,Mac Mouse Fix Helper,Terminal,kitty"
  '';
}
