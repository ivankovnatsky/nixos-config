{ pkgs, ... }:
{
  home = {
    packages = with pkgs; [ yamllint ];
    file.".config/yamllint/config".text = ''
      document-start: disable
    '';
  };
}
