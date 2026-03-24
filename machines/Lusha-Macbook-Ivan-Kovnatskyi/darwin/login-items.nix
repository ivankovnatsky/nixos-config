{ pkgs, ... }:

{
  system.activationScripts.postActivation.text = ''
    ${pkgs.settings}/bin/settings login add "Amethyst,Hammerspoon,Mac Mouse Fix,Stats" || true
  '';
}
