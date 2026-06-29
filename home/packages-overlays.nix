{ pkgs, ... }:

{
  home.packages = with pkgs; [
    passgen
    username
  ];
}
