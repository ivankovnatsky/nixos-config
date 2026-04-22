{ pkgs, ... }:

{
  system.activationScripts.postActivation.text = ''
    ${pkgs.settings}/bin/settings accessibility --enable "Amethyst,bash,Ghostty,Hammerspoon,kitty,Mac Mouse Fix Helper,Terminal"
  '';
}
