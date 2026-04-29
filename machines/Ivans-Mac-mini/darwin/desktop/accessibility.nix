{ pkgs, ... }:

{
  system.activationScripts.postActivation.text = ''
    ${pkgs.settings}/bin/settings accessibility --set "Ghostty,Hammerspoon,Mac Mouse Fix Helper,Terminal,kitty"
  '';
}
