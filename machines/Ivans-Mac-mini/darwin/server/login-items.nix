{ pkgs, ... }:

{
  system.activationScripts.postActivation.text = ''
    ${pkgs.settings}/bin/settings login set "Mac Mouse Fix" || true
  '';
}
