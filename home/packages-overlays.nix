{ pkgs, ... }:

{
  home.packages = with pkgs; [
    username
  ];
}
