{ pkgs, ... }:

{
  home.packages = with pkgs; [
    gwq
  ];
}
