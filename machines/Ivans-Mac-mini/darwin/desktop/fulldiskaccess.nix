{ pkgs, ... }:

{
  system.activationScripts.postActivation.text = ''
    ${pkgs.settings}/bin/settings fulldiskaccess --enable "Ghostty,kitty,smbd,Terminal"
  '';
}
