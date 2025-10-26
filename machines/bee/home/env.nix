{ config, osConfig, ... }:
{
  # Source transmission auth from sops template
  # Template defined in machines/bee/nixos/sops.nix
  home.sessionVariablesExtra = ''
    source ${osConfig.sops.templates."transmission-auth.env".path}
  '';
}
