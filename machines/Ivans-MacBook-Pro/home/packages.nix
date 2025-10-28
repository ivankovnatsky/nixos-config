{ pkgs, ... }:
{
  home.packages = with pkgs; [
    asusrouter-cli
    nodePackages.prettier
    swiftformat
    treefmt
    sops
    age
    ssh-to-age
  ];
}
