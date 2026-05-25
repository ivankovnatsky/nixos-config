{ pkgs, ... }:

{
  system.activationScripts.postActivation.text = ''
    ${pkgs.settings}/bin/settings accessibility set "bash,Hammerspoon,kitty,Mac Mouse Fix Helper,Terminal"
  '';
}
