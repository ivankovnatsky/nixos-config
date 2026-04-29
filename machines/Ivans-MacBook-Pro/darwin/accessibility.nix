{ pkgs, ... }:

{
  system.activationScripts.postActivation.text = ''
    ${pkgs.settings}/bin/settings accessibility --set "bash,Ghostty,Hammerspoon,kitty,Mac Mouse Fix Helper,Terminal"
  '';
}
