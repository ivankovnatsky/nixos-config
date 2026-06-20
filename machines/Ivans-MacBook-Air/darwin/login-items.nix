{ pkgs, ... }:

{
  system.activationScripts.postActivation.text = ''
    ${pkgs.settingsctl}/bin/settings login set "Hammerspoon" || true
  '';
}
