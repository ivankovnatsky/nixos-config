{ pkgs, ... }:

{
  system.activationScripts.postActivation.text = ''
    ${pkgs.settings}/bin/settings fulldiskaccess --enable "bash,determinate-nixd,Ghostty,kitty,smbd,sops-install-secrets,Terminal"
  '';
}
