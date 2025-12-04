{ pkgs, ... }:

{
  home.packages = with pkgs; [
    tree
    asusrouter-cli
    nodePackages.prettier
    treefmt
    sops
    age
    ssh-to-age
    syncthing-mgmt
    dns
    watchman-rebuild
  ];
}
