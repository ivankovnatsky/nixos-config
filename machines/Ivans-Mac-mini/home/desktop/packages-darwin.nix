{ pkgs, ... }:
{
  home.packages = with pkgs; [
    home-manager
    mkpasswd
    nixfmt
    syncthing
  ];
}
