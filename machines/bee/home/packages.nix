{ pkgs, ... }:
{
  home.packages = with pkgs; [
    pigz
    smartmontools
  ];
}
