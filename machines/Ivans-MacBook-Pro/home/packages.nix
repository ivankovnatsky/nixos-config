{ pkgs, ... }:
{
  home.packages = with pkgs; [
    nodePackages.prettier
    swiftformat
    treefmt
    sops
    age
    ssh-to-age
  ];
}
