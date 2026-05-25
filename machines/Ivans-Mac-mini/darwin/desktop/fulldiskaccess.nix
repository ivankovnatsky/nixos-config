{ pkgs, ... }:

{
  system.activationScripts.postActivation.text = ''
    ${pkgs.settings}/bin/settings fulldiskaccess --enable "bash,determinate-nixd,kitty,smbd,sops-install-secrets,Terminal"
  '';
}
