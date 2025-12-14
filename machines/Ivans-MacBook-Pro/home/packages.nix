{ pkgs, ... }:
{
  home.packages = with pkgs; [
    aria2
    switch-scaling
    tree
    asusrouter-cli
    nodePackages.prettier
    swiftformat
    treefmt
    sops
    age
    ssh-to-age
    syncthing-mgmt
    open-gh-notifications-py
    dns
    download-torrent
    watchman-rebuild
  ];
}
