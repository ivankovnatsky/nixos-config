{ pkgs, ... }:

{
  system.activationScripts.postActivation.text = ''
    ${pkgs.settings}/bin/settings login add "Hammerspoon,Mac Mouse Fix,Stats" || true
  '';
}
