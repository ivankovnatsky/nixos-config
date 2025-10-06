{ pkgs, ... }:
{
  home.packages = with pkgs; [
    smartmontools
  ];
}
