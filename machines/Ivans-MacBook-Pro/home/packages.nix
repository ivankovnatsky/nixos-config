{ pkgs, ... }:
{
  home.packages = with pkgs; [
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
    set-dns
    watchman-rebuild
  ];
}
