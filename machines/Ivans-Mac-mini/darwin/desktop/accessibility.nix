{ pkgs, ... }:

{
  system.activationScripts.postActivation.text = ''
    ${pkgs.settings}/bin/settings accessibility --enable "Amethyst,Discord,Ghostty,Hammerspoon,Mac Mouse Fix Helper,Terminal,kitty"
  '';
}
