{ pkgs, ... }:
{
  home.packages = with pkgs; [
    nodePackages.prettier
    swiftformat
    treefmt
  ];
}
