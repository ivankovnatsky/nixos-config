{ pkgs, ... }:
{
  home.packages = with pkgs; [
    age
    aria2
    asusrouter-cli
    dns
    download-torrent
    nodePackages.prettier
    open-gh-notifications-py
    ps-top-nu
    sops
    ssh-to-age
    swiftformat
    switch-scaling
    syncthing-mgmt
    tree
    treefmt
    watchman-rebuild
  ];
}
