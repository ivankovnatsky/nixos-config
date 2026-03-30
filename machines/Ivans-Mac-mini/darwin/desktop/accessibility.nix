{ pkgs, ... }:

{
  system.activationScripts.postActivation.text = ''
    ${pkgs.settings}/bin/settings accessibility --enable "Amethyst,Ghostty,Hammerspoon,Mac Mouse Fix Helper,Terminal,kitty"
  '';
}
