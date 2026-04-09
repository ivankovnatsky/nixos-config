{ pkgs, ... }:

{
  system.activationScripts.postActivation.text = ''
    ${pkgs.settings}/bin/settings accessibility --enable "Ghostty,Hammerspoon,Mac Mouse Fix Helper,Terminal,kitty"
  '';
}
