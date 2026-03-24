{ pkgs, ... }:

{
  system.activationScripts.postActivation.text = ''
    ${pkgs.settings}/bin/settings login add "Mac Mouse Fix" || true
  '';
}
