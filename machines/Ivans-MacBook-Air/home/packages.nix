{ pkgs, ... }:

{
  home.packages = with pkgs; [
    aria2
    switch-scaling
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
