{ pkgs, ... }:

{
  system.activationScripts.postActivation.text = ''
    ${pkgs.settingsctl}/bin/settings fulldiskaccess --enable "bash,determinate-nixd,kitty,smbd,sops-install-secrets,Terminal"
  '';
}
