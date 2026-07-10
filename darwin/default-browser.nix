{ pkgs, ... }:

{
  system.activationScripts.postActivation.text = ''
    ${pkgs.defaultbrowser}/bin/defaultbrowser firefoxdeveloperedition
  '';
}
