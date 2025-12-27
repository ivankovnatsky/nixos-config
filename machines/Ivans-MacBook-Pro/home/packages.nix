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
    poweron-homelab
    ps-top-nu
    sops
    ssh-to-age
    swiftformat
    settings
    syncthing-mgmt
    tree
    treefmt
    watchman-rebuild
  ];
}
